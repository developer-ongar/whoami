//
//  AnimeDetailReducer.swift
// 

import AnimeClient
import AnimeStreamLogic
import ComposableArchitecture
import DatabaseClient
import DownloaderClient
import Foundation
import Logger
import SharedModels
import UserDefaultsClient
import Utilities

// MARK: - AnimeDetailReducer

public struct AnimeDetailReducer: ReducerProtocol {
    public struct State: Equatable {
        public let animeId: Anime.ID
        public var anime: Loadable<Anime> = .idle
        public var stream: AnimeStreamLogic.State
        public var animeStore = Loadable<AnimeStore>.idle
        public var collectionStores = Loadable<[CollectionStore]>.idle
        public var episodesStatus = Set<DownloaderClient.EpisodeStorage>([])
        public var compactEpisodes = false
        public var episodesDescendingOrder = true

        public init(
            animeId: Anime.ID,
            anime: Loadable<Anime> = .idle,
            availableProviders: Selectable<ProviderInfo>
        ) {
            self.animeId = animeId
            self.anime = anime
            self.stream = .init(
                animeId: animeId,
                episodeId: -1,
                availableProviders: availableProviders
            )
        }
    }

    public enum Action: Equatable {
        case onAppear
        case retryAnimeFetch
        case tappedFavorite
        case addToCollectionToggle
        case closeButtonPressed
        case close
        case toggleCompactEpisodes
        case toggleEpisodeOrder
        case tappedCollectionList
        case showCollectionsList(Anime.ID, Set<CollectionStore>)
        case markEpisodeAsWatched(Episode.ID)
        case markEpisodeAsUnwatched(Int)
        case fetchedAnime(Loadable<Anime>)
        case selectedEpisode(Episode.ID)
        case downloadEpisode(Episode.ID)
        case episodesStatus(Set<DownloaderClient.EpisodeStorage>)
        case removeDownload(Episode.ID)
        case retryDownload(Episode.ID)
        case cancelDownload(Int)
        case play(anime: Anime, episodes: AnimeStreamingProvider, selected: Episode.ID)
        case fetchedAnimeFromDB([AnimeStore])
        case fetchedCollectionStores([CollectionStore])

        case stream(AnimeStreamLogic.Action)
    }

    @Dependency(\.mainQueue)
    var mainQueue
    @Dependency(\.animeClient)
    var animeClient
    @Dependency(\.downloaderClient)
    var downloaderClient
    @Dependency(\.databaseClient)
    var databaseClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Scope(state: \.stream, action: /Action.stream) {
            AnimeStreamLogic()
        }
        Reduce(self.core)
    }
}

public extension AnimeDetailReducer.State {
    init(
        anime: some AnimeRepresentable,
        availableProviders: Selectable<ProviderInfo>
    ) {
        self.init(
            animeId: anime.id,
            anime: (anime as? Anime).flatMap { .success($0) } ?? .idle,
            availableProviders: availableProviders
        )
    }
}

extension AnimeDetailReducer.State {
    var isLoadingAnime: Bool {
        guard let anime = anime.value else {
            return !anime.finished
        }
        return anime.status != .upcoming && (!animeStore.finished || !collectionStores.finished)
    }

    var isLoadingEpisodes: Bool {
        !episodes.finished
    }

    var isInACollection: Bool {
        guard let collections = collectionStores.value else {
            return false
        }
        return collections.contains { $0.animes.contains { animeStore in animeStore.id == animeId } }
    }

    var streamingProvider: Loadable<AnimeStreamingProvider>? {
        if let selected = stream.availableProviders.item {
            return stream.streamingProviders[selected.id]
        }
        return .idle
    }

    var episodes: Loadable<[Episode]> {
        if let streamingProvider {
            return streamingProvider.map(\.episodes)
        }
        return .idle
    }
}

extension AnimeDetailReducer {
    struct FetchingAnimeCancellable: Hashable {}
    struct FetchingEpisodesCancellable: Hashable {}
    struct CancelObservingAnimeDB: Hashable {}
    struct CancelObservingCollections: Hashable {}
    struct AddToCollectionDebounce: Hashable {}
    struct FavoritesDebouce: Hashable {}
    struct CancelObservingDownloadState: Hashable {}

    // swiftlint:disable cyclomatic_complexity
    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            state.compactEpisodes = userDefaultsClient.get(.compactEpisodes)
            state.episodesDescendingOrder = userDefaultsClient.get(.episodesDescendingOrder)

            if !state.anime.hasInitialized {
                return fetchAnime(&state)
            } else if case .success = state.anime {
                return startObservations(&state)
            }

        case .tappedFavorite:
            guard var animeStore = state.animeStore.value else {
                break
            }
            animeStore.isFavorite.toggle()

            return .run { [animeStore] _ in
                try await withTaskCancellation(id: FavoritesDebouce.self, cancelInFlight: true) {
                    if !(
                        try await databaseClient
                            .update(animeStore.id, \AnimeStore.isFavorite, animeStore.isFavorite)
                    ) {
                        try await databaseClient.insert(animeStore)
                    }
                }
            }

        case .addToCollectionToggle:
            guard let animeStore = state.animeStore.value else {
                break
            }
            guard let collectionStores = state.collectionStores.value else {
                break
            }

            return .run { _ in
                try await withTaskCancellation(
                    id: AddToCollectionDebounce.self,
                    cancelInFlight: true
                ) {
                    if var plannedCollections = collectionStores.first(where: { $0.title == .planning }) {
                        if !plannedCollections.animes.contains(where: { $0.id == animeStore.id }) {
                            plannedCollections.animes.append(animeStore)
                        } else {
                            plannedCollections.animes.removeAll { anime in
                                anime.id == animeStore.id
                            }
                        }
                        _ = try await databaseClient.insert(plannedCollections)
                    }
                }
            }

        case let .selectedEpisode(episodeId):
            guard let anime = state.anime.value, let streamingProvider = state.streamingProvider?.value else {
                break
            }
            return .init(
                value: .play(
                    anime: anime,
                    episodes: streamingProvider,
                    selected: episodeId
                )
            )

        case let .markEpisodeAsWatched(episodeNumber):
            guard var animeStore = state.animeStore.value,
                  let episode = state.episodes.value?[id: episodeNumber] else {
                break
            }

            animeStore.updateProgress(for: episode, progress: 1.0)

            return .run { [animeStore] in
                try await databaseClient.insert(animeStore)
            }

        case let .markEpisodeAsUnwatched(episodeNumber):
            guard let episodeStore = state.animeStore.value?.episodes.first(where: { $0.number == episodeNumber }) else {
                break
            }

            return .run { [episodeStore] in
                try await databaseClient.update(episodeStore.id, \EpisodeStore.progress, nil)
            }

        case .retryAnimeFetch:
            if state.anime.finished {
                return fetchAnime(&state)
            }

        case let .fetchedAnime(loaded):
            state.anime = loaded
            if case .success = loaded {
                return startObservations(&state)
            }

        case let .fetchedAnimeFromDB(animesMatched):
            guard let anime = state.anime.value else {
                break
            }
            state.animeStore = .success(.findOrCreate(anime, animesMatched))

        case let .fetchedCollectionStores(collectionStores):
            state.collectionStores = .success(collectionStores)

        case .toggleCompactEpisodes:
            state.compactEpisodes.toggle()

            return .run { [state] in
                await userDefaultsClient.set(.compactEpisodes, value: state.compactEpisodes)
            }

        case .toggleEpisodeOrder:
            state.episodesDescendingOrder.toggle()

            return .run { [state] in
                await userDefaultsClient.set(.episodesDescendingOrder, value: state.episodesDescendingOrder)
            }

        case .play:
            break

        case .closeButtonPressed:
            return .concatenate(
                .action(.stream(.destroy)),
                .cancel(id: FetchingAnimeCancellable.self),
                .cancel(id: FetchingEpisodesCancellable.self),
                .cancel(id: CancelObservingAnimeDB.self),
                .cancel(id: CancelObservingCollections.self),
                .cancel(id: CancelObservingDownloadState.self),
                .action(.close)
            )

        case .tappedCollectionList:
            return .action(
                .showCollectionsList(
                    state.animeId,
                    Set(state.collectionStores.value ?? [])
                )
            )

        case .showCollectionsList:
            break

        case .close:
            break

        case .downloadEpisode:
            break

        case let .episodesStatus(hm):
            state.episodesStatus = hm

        case let .removeDownload(episodeNumber):
            return .run { [state] in
                await downloaderClient.delete(state.animeId, episodeNumber)
            }

        case let .retryDownload(episodeNumber):
            return .run { [state] in
                await downloaderClient.retry(state.animeId, episodeNumber)
            }

        case let .cancelDownload(episodeNumber):
            let animeId = state.animeId
            return .run {
                await downloaderClient.cancel(animeId, episodeNumber)
            }

        case .stream:
            break
        }
        return .none
    }
}

extension AnimeDetailReducer {
    private func fetchAnime(_ state: inout State) -> EffectTask<Action> {
        let animeId = state.animeId
        state.anime = .loading

        return .run { send in
            await withTaskCancellation(id: FetchingAnimeCancellable.self, cancelInFlight: true) {
                await send(.fetchedAnime(.init { try await animeClient.getAnime(animeId) }))
            }
        }
    }

    private func startObservations(_ state: inout State) -> EffectTask<Action> {
        guard let anime = state.anime.value else {
            return .none
        }
        let animeId = anime.id
        var effects = [EffectTask<Action>]()

        if anime.status != .upcoming {
            effects.append(
                .action(.stream(.initialize))
            )

            effects.append(
                .run { send in
                    await withTaskCancellation(id: CancelObservingDownloadState.self) {
                        let items = downloaderClient.observe(animeId)

                        for await animes in items {
                            if let anime = animes.first {
                                await send(.episodesStatus(anime.episodes))
                            } else {
                                await send(.episodesStatus([]))
                            }
                        }
                    }
                }
            )
        }

        if !state.animeStore.hasInitialized {
            state.animeStore = .loading

            effects.append(
                .run { send in
                    let animeStoresStream: AsyncStream<[AnimeStore]> = databaseClient.observe(
                        AnimeStore.all.where(\AnimeStore.id == animeId).limit(1)
                    )

                    for try await animeStores in animeStoresStream {
                        await send(.fetchedAnimeFromDB(animeStores))
                    }
                }
                .cancellable(id: CancelObservingAnimeDB.self)
            )
        }

        if !state.collectionStores.hasInitialized {
            state.collectionStores = .loading

            effects.append(
                .run { send in
                    let collectionStores: AsyncStream<[CollectionStore]> = databaseClient.observe(
                        CollectionStore.all
                    )

                    for try await collection in collectionStores {
                        await send(.fetchedCollectionStores(collection))
                    }
                }
                .cancellable(id: CancelObservingCollections.self)
            )
        }

        return .merge(effects)
    }
}
