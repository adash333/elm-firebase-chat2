port module Main exposing (main)

import Browser exposing (Document, document)
import Browser.Dom as Dom
import Browser.Navigation as Nav
import Dialog
import Html exposing (..)
import Html.Attributes as At exposing (class, disabled, href, placeholder, src, style, type_, value, wrap)
import Html.Events exposing (on, onClick, onInput, onSubmit)
import Json.Decode as D exposing (Decoder, Error, decodeString, decodeValue, errorToString, field, map2, string)
import Json.Encode as E exposing (Value, object, string)
import List exposing (append, map, singleton)
import Random as R exposing (Generator, generate, int)
import SmoothScroll exposing (scrollTo)
import Task exposing (Task, attempt)



-- APP


main : Program Value Model Msg
main =
    document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveMessage NewMessage
        , receiveLocalStorage ReceiveLocalStorage
        ]



-- Incoming messages(PORT)


port receiveMessage : (Value -> msg) -> Sub msg


port receiveLocalStorage : (Value -> msg) -> Sub msg



-- Outgoing messages(PORT)


port postMessage : Value -> Cmd msg


port setLocalStorage : ( String, String ) -> Cmd msg


saveName : String -> Cmd msg
saveName name =
    setLocalStorage ( "name", name )


port getLocalStorage : String -> Cmd msg


getName : () -> Cmd msg
getName _ =
    getLocalStorage "name"



-- MODEL


type alias Name =
    String


type alias Message =
    String


type alias Talk =
    { name : Name
    , message : Message
    }


type Problem
    = MessageEmpty
    | DecodeError Error


type Status
    = Loading
    | Loaded
    | Failed


type alias Model =
    { name : Name
    , message : Message
    , history : List Talk
    , problems : List Problem
    , showDialog : Bool
    , status : Status
    }


type alias Item =
    { key : String
    , value : String
    }


init : Value -> ( Model, Cmd Msg )
init _ =
    ( { name = ""
      , message = ""
      , history = []
      , problems = []
      , showDialog = False
      , status = Loading
      }
    , getName ()
    )



-- UPDATE


type Msg
    = ReceiveLocalStorage Value
    | NewGuestName String
    | ChangeName Name
    | DecideName
    | ChangeMessage Message
    | Submit
    | NewMessage Value
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ReceiveLocalStorage value ->
            case decodeLocalStorage value of
                Ok pair ->
                    if pair.key == "name" then
                        ( { model | name = pair.value }
                        , Cmd.none
                        )

                    else
                        ( { model | showDialog = True }, Cmd.none )

                Err _ ->
                    ( { model | showDialog = True }, Cmd.none )

        NewGuestName number ->
            ( { model | name = "Guest-" ++ number }
            , Cmd.none
            )

        ChangeName name ->
            ( { model | name = name }
            , Cmd.none
            )

        DecideName ->
            ( { model | showDialog = False }
            , Cmd.batch
                [ if String.isEmpty <| String.trim model.name then
                    generate NewGuestName generateRandomNumber3

                  else
                    Cmd.none
                , saveName model.name
                ]
            )

        ChangeMessage message ->
            ( { model | message = message }
            , Cmd.none
            )

        Submit ->
            ( { model
                | message = ""
                , history = model.history
                , problems = []
              }
            , postMessage
                (E.object
                    [ ( "name", E.string model.name )
                    , ( "message", E.string model.message )
                    ]
                )
            )

        NewMessage value ->
            case decodeMessage value of
                Ok form ->
                    ( { model
                        | history =
                            append
                                model.history
                                [ form ]
                        , status = Loaded
                      }
                    , Task.attempt (always NoOp) (scrollTo "bottom")
                    )

                Err error ->
                    ( { model
                        | problems =
                            append
                                model.problems
                                [ DecodeError error ]
                        , status = Failed
                      }
                    , Cmd.none
                    )

        NoOp ->
            ( model, Cmd.none )


decodeMessage : Value -> Result Error Talk
decodeMessage value =
    case decodeValue recordDecoder value of
        Ok record ->
            decodeString formDecoder record.value

        Err error ->
            Err error


formDecoder : Decoder Talk
formDecoder =
    map2 Talk
        (field "name" D.string)
        (field "message" D.string)


recordDecoder : Decoder Item
recordDecoder =
    map2 Item
        (field "key" D.string)
        (field "value" D.string)


decodeLocalStorage : Value -> Result Error Item
decodeLocalStorage value =
    decodeValue localStorageDecoder value


localStorageDecoder : Decoder Item
localStorageDecoder =
    map2 Item
        (field "key" D.string)
        (field "value" D.string)


generateRandomNumber3 : Generator String
generateRandomNumber3 =
    R.map (String.padLeft 3 '0' << String.fromInt) <|
        int 0 999



-- VIEW


view : Model -> Document Msg
view model =
    { title = "ChatRoom"
    , body =
        [ nav [ class "navbar has-background-info is-fixed-top" ]
            [ div [ class "navbar-brand" ]
                [ a [ class "navbar-item has-text-white", href "#bottom" ]
                    [ text "Elm Firebase Bulma Chat" ]
                ]
            ]
        , viewDialog model
        , section [ class "section" ]
            [ div [ class "container" ]
                [ div
                    []
                  <|
                    case model.status of
                        Loading ->
                            [ div []
                                [ text "Loading" ]
                            ]

                        Loaded ->
                            List.map (viewHistory model.name) model.history

                        Failed ->
                            []
                , div [ At.id "bottom" ] [ viewForm model.message ]
                ]
            ]
        ]
    }


viewDialog : Model -> Html Msg
viewDialog model =
    Dialog.view
        (if model.showDialog then
            Just
                { closeMessage = Just DecideName
                , containerClass = Nothing
                , header = Nothing
                , body =
                    Just
                        (div [ class "modalmodal" ]
                            [ div [] [ text "Please enter your name." ]
                            , br [] []
                            , viewNameInput model.name
                            ]
                        )
                , footer =
                    Just
                        (a [ class "button is-success is-fullwidth", onClick DecideName ] [ text "OK" ])
                }

         else
            Nothing
        )


viewNameInput : Name -> Html Msg
viewNameInput name =
    Html.form [ onSubmit DecideName ]
        [ input [ placeholder "Name", value name, onInput ChangeName, class "input is-success" ] []
        ]


viewForm : Message -> Html Msg
viewForm message =
    div [ class "field has-addons" ]
        [ div [ class "control is-expanded" ]
            [ input [ class "input", placeholder "Message", type_ "text", value message, onInput ChangeMessage ]
                []
            ]
        , div [ class "control" ]
            [ a [ class "button is-info", onClick Submit, disabled <| String.isEmpty <| String.trim message ]
                [ text "Send" ]
            ]
        ]


viewHistory : Name -> Talk -> Html msg
viewHistory name talk =
    let
        messageClass =
            if talk.name == name then
                "self"

            else
                "others"
    in
    div []
        [ article [ class "media" ]
            [ if messageClass == "self" then
                div [] []

              else
                figure
                    [ class
                        "media-left"
                    ]
                    [ p [ class "image is-64x64" ]
                        [ img
                            [ class "is-rounded"
                            , src
                                (if messageClass == "self" then
                                    "img/usagi.png"

                                 else
                                    "img/kuma.png"
                                )
                            ]
                            []
                        ]
                    ]
            , div [ class "media-content media-body" ]
                [ div [ class "content" ]
                    [ p []
                        [ strong []
                            [ text talk.name ]
                        , div []
                            [ p [] <|
                                viewMultiLine talk.message
                            ]
                        ]
                    ]
                ]
            , if messageClass == "others" then
                div [] []

              else
                figure
                    [ class
                        "media-right"
                    ]
                    [ p [ class "image is-64x64" ]
                        [ img
                            [ class "is-rounded"
                            , src
                                (if messageClass == "self" then
                                    "img/usagi.png"

                                 else
                                    "img/kuma.png"
                                )
                            ]
                            []
                        ]
                    ]
            ]
        ]


viewMultiLine : Message -> List (Html msg)
viewMultiLine message =
    List.intersperse
        (br [] [])
        (List.map text <| String.split "\n" message)
