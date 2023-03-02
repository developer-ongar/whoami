//
//  SearchReducer.swift
//  

import AnimeClient
import ComposableArchitecture
import Foundation
import Logger
import SharedModels
import UserDefaultsClient
import Utilities

// MARK: - SearchReducer

public struct SearchReducer: ReducerProtocol {
    public struct State: Equatable {
        var query = ""
        var loadable = Loadable<[Anime]>.idle
        var searched = [String]()

        public init(
            query: String = "",
            loadable: Loadable<[Anime]> = Loadable<[Anime]>.idle,
            searched: [String] = [String]()
        ) {
            self.query = query
            self.loadable = loadable
            self.searched = searched
        }
    }

    public enum Action: Equatable {
        case onAppear
        case searchQueryChanged(String)
        case searchResult(Loadable<[Anime]>)
        case searchHistory([String])
        case clearSearchHistory
        case onAnimeTapped(Anime)
    }

    @Dependency(\.mainQueue)
    var mainQueue
    @Dependency(\.animeClient)
    var animeClient
    @Dependency(\.userDefaultsClient)
    var userDefaultsClient

    public init() {}

    public var body: some ReducerProtocol<State, Action> {
        Reduce(self.core)
    }
}

extension SearchReducer {
    struct SearchAnimesDebounceID: Hashable {}

    func core(state: inout State, action: Action) -> EffectTask<Action> {
        switch action {
        case .onAppear:
            return .run { send in
                await send(.searchHistory(userDefaultsClient.get(.searchedItems)))
            }

        case let .searchHistory(items):
            state.searched = items

        case let .searchQueryChanged(query):
            state.query = query

            guard !query.isEmpty else {
                state.loadable = .idle
                return .cancel(id: SearchAnimesDebounceID.self)
            }
            state.loadable = .loading

            return .run { send in
                try await withTaskCancellation(id: SearchAnimesDebounceID.self, cancelInFlight: true) {
                    try await mainQueue.sleep(for: .seconds(0.5))
                    await send(.searchResult(.init { try await animeClient.searchAnimes(query) }))
                }
            }

        case let .searchResult(loadable):
            state.loadable = loadable

        case .clearSearchHistory:
            state.searched.removeAll()
            return .fireAndForget { [state] in
                await userDefaultsClient.set(.searchedItems, value: state.searched)
            }

        case .onAnimeTapped:
            if state.searched.contains(state.query) {
                state.searched.removeAll(where: { $0 == state.query })
            }

            if state.searched.count > 9 {
                state.searched.removeLast()
            }
            state.searched.insert(state.query, at: 0)
            return .fireAndForget { [state] in
                await userDefaultsClient.set(.searchedItems, value: state.searched)
            }
        }
        return .none
    }
}
