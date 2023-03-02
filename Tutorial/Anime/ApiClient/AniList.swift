import Foundation
import SharedModels
import SociableWeaver
import Utilities


public final class AniListAPI: APIBase {
    public static let shared: AniListAPI = .init()

    // swiftlint:disable force_unwrapping
    public let base = URL(string: "")!

    private init() {}
}

public extension Request where Route == AniListAPI {
    static func graphql<Q: GraphQLQuery>(
        _: Q.Type,
        _ options: Q.QueryOptions
    ) -> Request<Route, Q.Response> {
        let query = Q.createQuery(options)

        let data = (try? GraphQL.Paylod(query: query.format()).toData()) ?? .init()

        return .init(
            method: .post(data)
        ) { _ in
            [
                "Content-Type": "application/json",
                "Content-Length": data.count
            ]
        }
    }
}

// MARK: - Converters

public extension AniListAPI {
    static func convert(from medias: [Media]) -> [Anime] {
        medias.compactMap { media in
            convert(from: media)
        }
    }

    static func convert(from media: Media) -> Anime {
        var coverImages: [ImageSize] = []

        if let imageStr = media.coverImage.extraLarge, let url = URL(string: imageStr) {
            coverImages.append(.large(url))
        }

        if let imageStr = media.coverImage.large, let url = URL(string: imageStr) {
            coverImages.append(.medium(url))
        }

        if let imageStr = media.coverImage.medium, let url = URL(string: imageStr) {
            coverImages.append(.small(url))
        }

        var posterImage: [ImageSize] = []
        if let imageStr = media.bannerImage, let url = URL(string: imageStr) {
            posterImage.append(.original(url))
        }

        let format: Anime.Format

        switch media.format {
        case .MOVIE:
            format = .movie
        case .TV:
            format = .tv
        case .TV_SHORT:
            format = .tvShort
        case .OVA:
            format = .ova
        case .ONA:
            format = .ona
        case .SPECIAL:
            format = .special
        }

        let status: Anime.Status

        switch media.status {
        case .FINISHED:
            status = .finished
        case .RELEASING:
            status = .current
        case .NOT_YET_RELEASED:
            status = .upcoming
        case .CANCELLED:
            status = .unreleased
        case .HIATUS:
            status = .tba
        }

        let averageScore: Double?

        if let averageRating = media.averageScore {
            averageScore = Double(averageRating) / 100.0
        } else {
            averageScore = nil
        }

        return Anime(
            id: media.id,
            malId: media.idMal,
            title: media.title.english ?? media.title.romaji ?? media.title.native ?? "Untitled",
            description: media.description?.trimHTMLTags() ?? "No description",
            posterImage: coverImages,
            coverImage: posterImage,
            categories: media.genres.prefix(3).sorted(),
            status: status,
            format: format,
            releaseYear: media.startDate.year,
            avgRating: averageScore
        )
    }
}

// MARK: - PageResponseObject

public protocol PageResponseObject {
    static var pageResponseName: String { get }
}

public extension AniListAPI {
    typealias PageMediaQuery = PageQuery<AniListAPI.Media>

    struct PageQuery<O: GraphQLQueryObject & PageResponseObject>: GraphQLQuery {
        public typealias Response = GraphQL.Response<PageResponse<Self>>

        public enum QueryArgument: DefaultArguments {
            case page(Int = 1)
            case perPage(Int = 25)

            public static var defaultArgs: [QueryArgument] { [.page(), .perPage()] }
        }

        public struct QueryOptions {
            public var arguments: [QueryArgument]
            public var itemArguments: [O.Argument]

            public init(
                arguments: [QueryArgument] = .defaultArgs,
                itemArguments: [O.Argument] = []
            ) {
                self.arguments = arguments
                self.itemArguments = itemArguments
            }
        }

        public let pageInfo: AniListAPI.PageInfo
        public let items: [O]

        public enum CodingKeys: CodingKey {
            case pageInfo
            case items

            public init?(stringValue: String) {
                if stringValue == Self.pageInfo.stringValue {
                    self = .pageInfo
                } else if stringValue == Self.items.stringValue {
                    self = .items
                } else {
                    return nil
                }
            }

            public var stringValue: String {
                switch self {
                case .pageInfo:
                    return "pageInfo"
                case .items:
                    return O.pageResponseName
                }
            }
        }

        public static func createQuery(_ options: QueryOptions) -> SociableWeaver.Weave {
            Weave(.query) {
                var obj = Object("Page") {
                    O.createQueryObject(CodingKeys.items, options.itemArguments)
                    AniListAPI.PageInfo.createQueryObject(CodingKeys.pageInfo)
                }
                .caseStyle(.pascalCase)

                for argument in options.arguments {
                    switch argument {
                    case let .page(int):
                        obj = obj.argument(key: "page", value: int)
                    case let .perPage(int):
                        obj = obj.argument(key: "perPage", value: int)
                    }
                }
                return "{ \(obj.description) }"
            }
        }
    }
}

// MARK: - GraphQL Models

public extension AniListAPI {
    struct PageResponse<T: Decodable>: Decodable {
        // swiftlint:disable identifier_name
        public let Page: T
    }

    struct PageInfo: GraphQLQueryObject {
        public typealias Argument = Void

        let total: Int
        let perPage: Int
        let currentPage: Int
        let lastPage: Int
        let hasNextPage: Bool

        public static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.total)
                Field(CodingKeys.perPage)
                Field(CodingKeys.currentPage)
                Field(CodingKeys.lastPage)
                Field(CodingKeys.hasNextPage)
            }
        }
    }

    struct FuzzyDate: GraphQLQueryObject {
        public typealias Argument = Void

        let year: Int?
        let month: Int?
        let day: Int?

        public static func createQueryObject(
            _ name: CodingKey
        ) -> Object {
            Object(name) {
                Field(CodingKeys.year)
                Field(CodingKeys.month)
                Field(CodingKeys.day)
            }
        }
    }

    struct MediaResponse: Decodable {
        public let Media: Media
    }

    struct Media: GraphQLQuery, GraphQLQueryObject, PageResponseObject {
        public typealias Response = GraphQL.Response<MediaResponse>

        public static var pageResponseName: String { "media" }

        let id: Int
        let idMal: Int?
        let title: Title
        let type: MediaType
        let format: Format
        let status: Status
        let description: String?
        let seasonYear: Int?
        let coverImage: MediaCoverImage
        let bannerImage: String?
        let startDate: FuzzyDate
        let averageScore: Int?
        let genres: [String]

        public enum Argument: DefaultArguments {
            case id(Int)
            case idIn([Int])
            case isAdult(Bool = false)
            case type(MediaType = .ANIME)
            case formatIn([Format] = Format.allCases)
            case sort([TrendSort])
            case status(Status)
            case statusIn([Status])
            case statusNot(Status)
            case statusNotIn([Status])
            case search(String)

            public static let defaultArgs: [Argument] = {
                [.isAdult(), .type(), .formatIn()]
            }()
        }

        public static func createQueryObject(
            _ name: String,
            _ arguments: [Argument] = .defaultArgs
        ) -> Object {
            var obj = Object(name) {
                Field(CodingKeys.id)
                Field(CodingKeys.idMal)
                Title.createQueryObject(CodingKeys.title)
                Field(CodingKeys.type)
                Field(CodingKeys.format)
                Field(CodingKeys.status)
                Field(CodingKeys.description)
                Field(CodingKeys.seasonYear)
                MediaCoverImage.createQueryObject(CodingKeys.coverImage)
                Field(CodingKeys.bannerImage)
                FuzzyDate.createQueryObject(CodingKeys.startDate)
                Field(CodingKeys.averageScore)
                Field(CodingKeys.genres)
            }

            for argument in arguments {
                switch argument {
                case let .id(id):
                    obj = obj.argument(key: "id", value: id)
                case let .idIn(ids):
                    obj = obj.argument(key: "id_in", value: ids)
                case let .isAdult(bool):
                    obj = obj.argument(key: "isAdult", value: bool)
                case let .type(mediaType):
                    obj = obj.argument(key: "type", value: mediaType)
                case let .formatIn(formats):
                    obj = obj.argument(key: "format_in", value: formats)
                case let .sort(sort):
                    obj = obj.argument(key: "sort", value: sort)
                case let .search(query):
                    obj = obj.argument(key: "search", value: query)
                case let .status(status):
                    obj = obj.argument(key: "status", value: status)
                case let .statusIn(status):
                    obj = obj.argument(key: "status_in", value: status)
                case let .statusNot(status):
                    obj = obj.argument(key: "status_not", value: status)
                case let .statusNotIn(status):
                    obj = obj.argument(key: "status_not_in", value: status)
                }
            }
            return obj
        }

        public static func createQuery(
            _ arguments: [Media.Argument] = .defaultArgs
        ) -> Weave {
            enum CodingKeys: CodingKey {
                case Media
            }

            return Weave(.query) {
                Self.createQueryObject(CodingKeys.Media, arguments)
                    .caseStyle(.pascalCase)
            }
        }

        public enum TrendSort: EnumValueRepresentable {
            case ID
            case ID_DESC
            case MEDIA_ID
            case MEDIA_ID_DESC
            case DATE
            case DATE_DESC
            case SCORE
            case SCORE_DESC
            case POPULARITY
            case POPULARITY_DESC
            case TRENDING
            case TRENDING_DESC
            case EPISODE
            case EPISODE_DESC
        }

        public struct MediaCoverImage: GraphQLQueryObject {
            public typealias Argument = Void

            let extraLarge: String?
            let large: String?
            let medium: String?

            static func createQueryObject(
                _ name: CodingKey
            ) -> Object {
                Object(name) {
                    Field(CodingKeys.extraLarge)
                    Field(CodingKeys.large)
                    Field(CodingKeys.medium)
                }
            }
        }

        public enum Status: String, Decodable, EnumValueRepresentable {
            case FINISHED
            case RELEASING
            case NOT_YET_RELEASED
            case CANCELLED
            case HIATUS
        }

        public enum Format: String, Decodable, EnumValueRepresentable, CaseIterable {
            case TV
            case TV_SHORT
            case MOVIE
            case SPECIAL
            case OVA
            case ONA
        }

        public enum MediaType: String, Decodable, EnumRawValueRepresentable {
            case ANIME
            case MANGA
        }

        public struct Title: GraphQLQueryObject {
            public typealias Argument = Void

            let romaji: String?
            let english: String?
            let native: String?
            let userPreferred: String?

            static func createQueryObject(
                _ name: CodingKey
            ) -> Object {
                Object(name) {
                    Field(CodingKeys.romaji)
                    Field(CodingKeys.english)
                    Field(CodingKeys.native)
                    Field(CodingKeys.userPreferred)
                }
            }
        }
    }
}
