//
//  Copyright (c) 2015 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

// MARK: - Constants

struct Constants {

    // MARK: NotificationKeys
    
    struct NotificationKeys {
        static let SignedIn = "onSignInCompleted"
    }
    
    // MARK: MessageFields

    struct PlayerFields {
        static let name = "name"
        static let playerIdentifier = "playeridentifier"
        static let playerState = "state"
        static let playerGameState = "gamestate"
        static let gamePlayerIdentifier = "gameplayeridentifier"
        static let gamePlayerName = "gameplayername"
        static let score = "score"
        
        static let pictURL = "photoUrl"
    }
}
