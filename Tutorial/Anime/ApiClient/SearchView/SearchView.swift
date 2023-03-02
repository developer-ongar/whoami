//
//  SearchView.swift
//  

import ComposableArchitecture
import SharedModels
import SwiftUI
import SwiftUINavigation
import Utilities
import ViewComponents

// MARK: - SearchView

public struct SearchView: View {
    let store: StoreOf<SearchReducer>

    public init(
        store: StoreOf<SearchReducer>
    ) {
        self.store = store
    }

    public var body: some View {
        VStack {
            ExtraTopSafeAreaInset()
                .fixedSize()

            WithViewStore(store) { state in
                state
            } content: { viewStore in
                HStack {
                    searchBar

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .frame(maxHeight: .infinity)
                        .onTapGesture {
                            viewStore.send(
                                .searchQueryChanged("")
                            )
                        }
                        .opacity(viewStore.query.isEmpty ? 0.0 : 1.0)
                }
                .fixedSize(horizontal: false, vertical: true)
                .padding()
                .background(Color.gray.opacity(0.15))
                .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal)

            WithViewStore(
                store.scope(
                    state: \.loadable
                )
            ) { viewStore in
                switch viewStore.state {
                case .idle:
                    waitingForTyping
                case .loading:
                    loadingSearches
                case let .success(animes):
                    presentAnimes(animes)
                case .failed:
                    failedToRetrieve
                }
            }
        }
        .padding(.top)
        #if os(macOS)
            .padding(.horizontal, 40)
        #endif
    }
}

extension SearchView {
    @ViewBuilder
    var searchBar: some View {
        WithViewStore(
            store,
            observe: \.query
        ) { viewStore in
            if #available(iOS 15.0, macOS 12.0, *) {
                FocusOnAppearTextField(
                    title: "Search",
                    text: viewStore.binding(
                        get: { $0 },
                        send: SearchReducer.Action.searchQueryChanged
                    )
                    .removeDuplicates()
                )
                .textFieldStyle(.plain)
                .frame(maxHeight: .infinity)
            } else {
                TextField(
                    "Search",
                    text: viewStore.binding(
                        get: { $0 },
                        send: SearchReducer.Action.searchQueryChanged
                    )
                )
                .textFieldStyle(.plain)
                .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    var searchHistory: some View {
        WithViewStore(
            store,
            observe: \.searched
        ) { viewStore in
            if !viewStore.state.isEmpty {
                VStack(alignment: .leading) {
                    HStack {
                        Text("Search History")
                            .bold()
                            .foregroundColor(.gray)
                        Spacer()
                        Text("Clear")
                            .foregroundColor(.red)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewStore.send(
                                    .clearSearchHistory,
                                    animation: .easeInOut(duration: 0.25)
                                )
                            }
                    }
                    .font(.body)

                    ScrollView(.horizontal) {
                        HStack {
                            ForEach(
                                Array(zip(viewStore.state.indices, viewStore.state)),
                                id: \.0
                            ) { _, search in
                                ChipView(text: search)
                                    .onTapGesture {
                                        viewStore.send(.searchQueryChanged(search))
                                    }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    @ViewBuilder
    var waitingForTyping: some View {
        VStack(spacing: 24) {
            searchHistory
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 70))

            Text("Start typing to search")
                .font(.title2)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    var loadingSearches: some View {
        ProgressView()
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    func presentAnimes(_ animes: [Anime]) -> some View {
        if !animes.isEmpty {
            ScrollView {
                ZStack {
                    VStack {
                        LazyVGrid(
                            columns: .init(
                                repeating: .init(
                                    .flexible(),
                                    spacing: 16
                                ),
                                count: DeviceUtil.isPhone ? 2 : 6
                            )
                        ) {
                            ForEach(animes, id: \.id) { anime in
                                AnimeItemView(anime: anime)
                                    .onTapGesture {
                                        ViewStore(store.stateless).send(.onAnimeTapped(anime))
                                        #if os(iOS)
                                        UIApplication.shared
                                            .windows
                                            .first(where: \.isKeyWindow)?
                                            .endEditing(true)
                                        #endif
                                    }
                            }
                        }
                        .padding([.top, .horizontal])

                        ExtraBottomSafeAreaInset()
                        Spacer(minLength: 32)
                    }

                    #if os(iOS)
                    GeometryReader { reader in
                        Color.clear
                            .onChange(
                                of: reader.frame(in: .named("scroll")).minY
                            ) { _ in
                                UIApplication.shared
                                    .windows
                                    .first(where: \.isKeyWindow)?
                                    .endEditing(true)
                            }
                    }
                    #endif
                }
            }
            .coordinateSpace(name: "scroll")
        } else {
            noResultsFound
        }
    }

    @ViewBuilder
    var failedToRetrieve: some View {
        VStack(spacing: 8) {
            searchHistory
            Spacer()
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 22))

            Text("There is an error fetching items.")
                .font(.headline)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .foregroundColor(.red)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    @ViewBuilder
    var noResultsFound: some View {
        VStack(spacing: 16) {
            searchHistory
            Spacer()
            Text("No results found.")
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

// MARK: - SearchView_Previews

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SearchView(
                store: .init(
                    initialState: .init(
                        query: "Test",
                        loadable: .success([]),
                        searched: ["Testy", "Attack on Titans"]
                    ),
                    reducer: SearchReducer()
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("With history")

            SearchView(
                store: .init(
                    initialState: .init(
                        query: "",
                        loadable: .idle,
                        searched: []
                    ),
                    reducer: SearchReducer()
                )
            )
            .preferredColorScheme(.dark)
            .previewDisplayName("Empty")
        }
    }
}

// MARK: - FocusOnAppearTextField

@available(iOS 15.0, macOS 12.0, *)
struct FocusOnAppearTextField: View {
    let title: any StringProtocol
    let text: Binding<String>

    @FocusState
    private var focused: Bool

    var body: some View {
        TextField(title, text: text)
            .focused($focused)
            .onAppear {
                DispatchQueue.main.async {
                    self.focused = true
                }
            }
    }
}
