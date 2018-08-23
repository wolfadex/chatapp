port module Main exposing (main)


import Browser exposing (Document)
import Browser.Dom as Dom
import Debug exposing (log)
import Dict exposing (Dict)
import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Event
import Json.Decode as JD exposing (Value)
import Json.Encode as JE
import Task



---- MAIN ----


main : Program Value Model Msg
main =
    Browser.document
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch [ receiveMessage decodeReceivedMessagePort
              , loggedIn (\_ -> LoggedIn)
              , foundOrganization decodeFoundOrganizationPort
              ]


decodeReceivedMessagePort : Value -> Msg
decodeReceivedMessagePort messageJson =
    case JD.decodeValue decodeReceivedMessage messageJson of
        Ok message ->
            NewChatMessage message
        Err err ->
            ErrorMessage err


decodeReceivedMessage : JD.Decoder ChatMessage
decodeReceivedMessage =
    JD.map ChatMessage
        (JD.field "content" JD.string)


decodeFoundOrganizationPort : Value -> Msg
decodeFoundOrganizationPort organizationJson =
    case JD.decodeValue decodeFoundOrganization organizationJson of
      Ok message ->
          NewOrganizationFound message
      Err err ->
          ErrorMessage err


decodeFoundOrganization : JD.Decoder Organization
decodeFoundOrganization =
    JD.map4 Organization
        (JD.field "name" JD.string)
        (JD.field "namespace" JD.string)
        (JD.field "rooms" <| JD.succeed Dict.empty) -- TODO
        (JD.succeed Nothing)




---- PORTS ----

-- Outgoing
port newMessage : String -> Cmd msg
port login : String -> Cmd msg
port createOrganization : String -> Cmd msg

-- Incoming
port receiveMessage : (Value -> msg) -> Sub msg
-- port loginMessage : (Value -> msg) -> Sub msg
-- port disconnectMessage : (Value -> msg) -> Sub msg
port loggedIn : (String -> msg) -> Sub msg
port foundOrganization : (Value -> msg) -> Sub msg



---- TYPES ----


type AuthStatus
    = ASLoggedOut
    | ASLoggingIn
    | ASLoggedIn


type DisplayStatus
    = Online
    | Away
    | Busy
    | Offline


type alias User =
    { username : String
    , authStatus : AuthStatus
    , displayStatus : DisplayStatus
    }


newUser : User
newUser =
    { username = ""
    , authStatus = ASLoggedOut
    , displayStatus = Offline
    }


type alias Organization =
    { name : String
    , namespace : String
    , rooms : Dict String Room
    , activeRoom : Maybe Room
    }


type alias Channel =
    { name : String
    , room : String
    }


type alias Group =
    { name : List String
    , room : String
    }


type Room
    = RChannel Channel
    | RGroup Group


type Direction
    = Joining
    | Leaving


type alias StatusMessage =
    { user : String
    , direction : Direction
    }


type alias ChatMessage =
    { content : String }


type Message
    = MChat ChatMessage
    | MStatus StatusMessage


type Msg
    = NoOp
    | ErrorMessage JD.Error
    | UserInput String
    | SendMessage
    | NewChatMessage ChatMessage
    | UpdateUserName String
    | SubmitUserName String
    | LoggedIn
    | ShowNewOrgModal Bool
    | UpdateNewOrgName String
    | CreateOrganization String
    | NewOrganizationFound Organization
    | SetActiveOrg Organization


type alias Model =
    { userInput : ChatMessage
    , chatLog : List Message
    , user : User
    , organizations : Dict String Organization
    , activeOrganization : Maybe Organization
    , showNewOrgModal : Bool
    , newOrgName : String
    }



---- INIT ----


init : Value -> (Model, Cmd Msg)
init flags =
    ( { userInput = emptyMessage
      , chatLog = []
      , user = newUser
      , organizations = Dict.empty
      , activeOrganization = Nothing
      , showNewOrgModal = False
      , newOrgName = ""
      }
    , Cmd.batch [ focusField "input-username"
                ]
    )


emptyMessage : ChatMessage
emptyMessage =
    { content = "" }



---- UPDATE ----


focusField : String -> Cmd Msg
focusField fieldId =
    Task.attempt (\_ -> NoOp) (Dom.focus fieldId)


update : Msg -> Model -> (Model, Cmd Msg)
update msg ({ userInput, chatLog, user, organizations } as model) =
    case msg of
        NoOp ->
            ( model, Cmd.none )
        ErrorMessage err ->
            log (Debug.toString err) ( model, Cmd.none )
        UserInput input ->
            ( { model | userInput = updateUserInput userInput input }
            , Cmd.none
            )
        SendMessage ->
            ( { model | userInput = emptyMessage }
            , newMessage userInput.content
            )
        NewChatMessage message ->
            ( { model | chatLog = (MChat message)::chatLog }
            , Cmd.none
            )
        UpdateUserName name ->
            ( { model | user = updateUserName user name }
            , Cmd.none
            )
        SubmitUserName name ->
            ( { model | user = setAuthStatus user ASLoggingIn }
            , login name
            )
        LoggedIn ->
            ( { model | user = setAuthStatus user ASLoggedIn }
            , Cmd.none
            )
        ShowNewOrgModal showOrHide ->
            ( { model
              | showNewOrgModal = showOrHide
              , newOrgName = ""
              }
            , focusField "input-orgname"
            )
        UpdateNewOrgName newName ->
            ( { model | newOrgName = newName }
            , Cmd.none
            )
        CreateOrganization name ->
            ( { model | showNewOrgModal = False }
            , createOrganization name
            )
        NewOrganizationFound ({ name } as organization) ->
            ( { model
              | organizations = Dict.insert name organization organizations
              , activeOrganization = Just organization
              }
            , Cmd.none
            )
        SetActiveOrg organization ->
            ( { model | activeOrganization = Just organization }
            , Cmd.none
            )


updateUserInput : ChatMessage -> String -> ChatMessage
updateUserInput userInput newContent =
    { userInput | content = newContent }


updateUserName : User -> String -> User
updateUserName user name =
    { user | username = name }


setAuthStatus : User -> AuthStatus -> User
setAuthStatus user status =
    { user | authStatus = status }



---- VIEW ----


view : Model -> Document Msg
view ({ user } as model) =
    { title = "Chat Carl"
    , body = case user.authStatus of
        ASLoggedOut ->
            [ loginView user ]
        ASLoggingIn ->
            [ Html.text "Logging In ..." ]
        ASLoggedIn ->
            [ chatView model  ]
    }


loginView : User -> Html Msg
loginView { username } =
    Html.form [ Attr.class "app--login"
              , Event.onSubmit <| SubmitUserName username
              ]
              [ Html.input [ Attr.value username
                           , Event.onInput UpdateUserName
                           , Attr.placeholder "Enter a username"
                           , Attr.class "login"
                           , Attr.required True
                           , Attr.id "input-username"
                           ]
                           []
              , Html.button []
                            [ Html.text "Join" ]
              ]


chatView : Model -> Html Msg
chatView { chatLog, userInput, organizations, showNewOrgModal, newOrgName, activeOrganization } =
    Html.div [ Attr.class "app--logged-in" ]
             [ organizationsView organizations activeOrganization
             , roomsView activeOrganization
             , currentChatView activeOrganization chatLog userInput
             , modalView showNewOrgModal ShowNewOrgModal "Create New Organization" (newOrgView newOrgName)
             ]


modalView : Bool -> (Bool -> Msg) -> String -> Html Msg -> Html Msg
modalView visible closeModalMessage title content =
    if visible then
        Html.div [ Attr.class "modal-view" ]
                 [ Html.div [ Attr.class "modal-view__modal" ]
                            [ Html.div [ Attr.class "modal-view__modal__header" ]
                                       [ Html.button [ Event.onClick <| closeModalMessage False
                                                     , Attr.class "modal-view__modal__header__close-button"
                                                     ]
                                                     [ Html.text "X" ]
                                       , Html.div [ Attr.class "modal-view__modal__header__title" ]
                                                  [ Html.text title ]
                                       ]
                            , Html.div [ Attr.class "modal-view__modal__body" ]
                                       [ content ]
                            ]
                 ]
    else
        Html.text ""



organizationsView : Dict String Organization -> Maybe Organization -> Html Msg
organizationsView organizations activeOrganization =
    Html.ul [ Attr.class "app--loggedin__organizations" ]
            <| addOrgView
               :: (List.map (organizationView activeOrganization) <| Dict.toList organizations)


addOrgView : Html Msg
addOrgView =
    Html.li [ Attr.class "app--loggedin__organizations__organization" ]
            [ Html.button [ Event.onClick <| ShowNewOrgModal True ]
                          [ Html.text "+" ]
            ]


organizationView : Maybe Organization -> (String, Organization) -> Html Msg
organizationView activeOrganization (id, ({ name } as organization)) =
    let
        activeClass = case activeOrganization of
                          Just org ->
                                if organization == org then
                                    " active-org"
                                else
                                    ""
                          Nothing ->
                              ""
    in
        Html.li [ Attr.class ("app--loggedin__organizations__organization" ++ activeClass)
                ]
                [ Html.button [ Event.onClick <| SetActiveOrg organization ]
                              [ Html.text name ]
                ]


roomsView : Maybe Organization -> Html Msg
roomsView activeOrganization =
    let
        (channels, groups, active) = case activeOrganization of
            Just { rooms } ->
                List.foldl splitRoomsByType ([], [], True) (Dict.toList rooms)
            Nothing ->
                ([], [], False)
    in
        Html.div [ Attr.class "app--loggedin__rooms" ]
                 [ Html.ul [ Attr.class "app--loggedin__rooms__channels" ]
                           <| if active then
                                  [ Html.li [] [ Html.text "Channels" ]
                                  , Html.li [] [ Html.button [] [ Html.text "+" ] ]
                                  ] ++ (List.map roomView channels)
                              else
                                  []
                 , Html.ul [ Attr.class "app--loggedin__rooms__groups" ]
                           <| if active then
                                  [ Html.li [] [ Html.text "Direct Messages" ]
                                  , Html.li [] [ Html.button [] [ Html.text "+" ] ]
                                  ] ++ (List.map roomView groups)
                              else
                                  []
                 ]


splitRoomsByType : (String, Room) -> (List Room, List Room, Bool) -> (List Room, List Room, Bool)
splitRoomsByType (name, room) (channels, groups, active) =
    case room of
        RChannel channel ->
            (RChannel channel :: channels, groups, active)
        RGroup group ->
            (channels, RGroup group :: groups, active)


roomView : Room -> Html Msg
roomView room =
    case room of
        RChannel { name } ->
            Html.li [] [ Html.text name ]
        RGroup { name } ->
            Html.li [] [ Html.text <| String.join ", " name ]


currentChatView : Maybe Organization -> List Message -> ChatMessage -> Html Msg
currentChatView activeOrg chatLog userInput =
    let
        active = case activeOrg of
            Just { activeRoom } ->
                case activeRoom of
                    Just _ ->
                        True
                    Nothing ->
                        False
            Nothing ->
                False
    in
        Html.div [ Attr.class "app--loggedin__chat" ]
                 [ chatLogView chatLog
                 , userInputView active userInput
                 ]


userInputView : Bool -> ChatMessage -> Html Msg
userInputView active { content } =
    Html.div [ Attr.class "message-box" ]
             [ Html.textarea [ Attr.value content
                             , Event.onInput UserInput
                             , Attr.class "message-box__input"
                             , Attr.disabled <| not active
                             ]
                           []
             , Html.button [ Attr.class "message-box__send-button"
                           , Event.onClick SendMessage
                           , Attr.disabled <| not active
                           ]
                           [ Html.text "Send" ]
             ]


chatLogView : List Message -> Html Msg
chatLogView chatLog =
    Html.ul [ Attr.class "chat-log" ]
            <| List.map chatMessageView chatLog


chatMessageView : Message -> Html Msg
chatMessageView message =
    case message of
        MChat { content }  ->
            Html.li [] [ Html.text content ]
        MStatus statusMessage ->
            Html.li [] [ Html.text "Status Message" ]


newOrgView : String -> Html Msg
newOrgView newOrgName =
    Html.form [ Event.onSubmit <| CreateOrganization newOrgName ]
              [ Html.input [ Attr.id "input-orgname"
                           , Attr.value newOrgName
                           , Event.onInput UpdateNewOrgName
                           ]
                           []
              , Html.button [] [ Html.text "Create" ]
              ]
