//
//  ViewController.swift
//  Emoji Matching
//
//  Created by Hanyu Yang on 2020/12/18.
//

import UIKit
import Foundation

let allCardBacks = Array("🎆🎇🌈🌅🌇🌉🌃🌄⛺⛲🚢🌌🌋🗽")
let allEmojiCharacters = Array("🚁🐴🐇🐢🐱🐌🐒🐞🐫🐠🐬🐩🐶🐰🐼⛄🌸⛅🐸🐳❄❤🐝🌺🌼🌽🍌🍎🍡🏡🌻🍉🍒🍦👠🐧👛🐛🐘🐨😃🐻🐹🐲🐊🐙")

extension Array {
  mutating func shuffle() {
    for i in 0..<(count - 1) {
      let j = Int(arc4random_uniform(UInt32(count - i))) + i
      self.swapAt(i, j)
    }
  }
}

func delay(_ delay:Double, closure:@escaping ()->()) {
  let when = DispatchTime.now() + delay
  DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
}

class ViewController: UIViewController {

    var game = MatchingGame(numPairs: 10)
    @IBOutlet var cardButtons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateView()
        print(game.getCheatString())
    }
    
    @IBAction func pressedNewGame(_ sender: Any) {
        refreshNewGame()
    }
    
    @IBAction func pressedCardButton(_ sender: Any) {
        let button = sender as! UIButton
        game.pressedCard(atIndex: button.tag)
        updateView()
        if game.gameState == MatchingGame.GameState.turnComplete {
            delay(1.2) {
                self.game.startNewTurn()
                if(self.game.gameState == MatchingGame.GameState.over) {
                    self.refreshNewGame()
                }
                self.updateView()
            }
        }
    }
    
    func refreshNewGame() {
        game = MatchingGame(numPairs: 10)
        updateView()
        print(game.getCheatString())
    }
    
    func updateView(){
        for button in cardButtons {
            let index = button.tag
            switch game.cardStates[index] {
            case .hidden:
                button.setTitle(String(game.cardBack), for: .normal)
            case .revealed:
                button.setTitle(String(game.cards[index]), for: .normal)
            case .removed:
                button.setTitle(" ", for: .normal)
            }
        }
    }
}

class MatchingGame: CustomStringConvertible {
    
    enum State: String {
        case hidden = "_"
        case revealed = "+"
        case removed = "-"
    }
    
    enum GameState: String {
        case wait1 = "Waiting for first flip"
        case wait2 = "Waiting for second flip"
        case turnComplete = "Turn Completed"
        case over = "Game Over"
    }
    
    var cardStates: [State]
    var cards: [Character]
    var cardBack: Character
    var firstCardIndex: Int?, secondCardIndex: Int?
    var gameState: GameState
    
    init(numPairs: Int) {
        cardStates = [State](repeating: .hidden, count: numPairs * 2)
        gameState = .wait1
        var emojiSymbolsUsed = [Character]()
        while emojiSymbolsUsed.count < numPairs {
          let index = Int(arc4random_uniform(UInt32(allEmojiCharacters.count)))
          let symbol = allEmojiCharacters[index]
          if !emojiSymbolsUsed.contains(symbol) {
            emojiSymbolsUsed.append(symbol)
          }
        }
        cards = emojiSymbolsUsed + emojiSymbolsUsed
        cards.shuffle()

        // Randomly select a card back for this round
        let index = Int(arc4random_uniform(UInt32(allCardBacks.count)))
        cardBack = allCardBacks[index]
    }
    
    func getCardsString() -> String {
        var gameString = ""
        var lineCount = 0
        for index in 0..<cards.count {
            if cardStates[index] == State.hidden {
                gameString += String(cardBack)
            } else if cardStates[index] == State.revealed {
                gameString += String(cards[index])
            } else {
                gameString += "X"
            }
            lineCount += 1
            if (lineCount == 4) {
                gameString += "\n"
                lineCount = 0
            }
        }
        return gameString
    }
    
    func getCheatString() -> String {
        var gameString = ""
        var lineCount = 0
        for char in cards {
            gameString += String(char)
            lineCount += 1
            if (lineCount == 4) {
                gameString += "\n"
                lineCount = 0
            }
        }
        return gameString
    }

    var description: String {
        return "\(gameState) Cards: \(getCardsString())"
    }

    func pressedCard(atIndex: Int) {
        if gameState == GameState.turnComplete || gameState == GameState.over {
            return
        }
        if cardStates[atIndex] != State.hidden {
            return
        }
        cardStates[atIndex] = State.revealed
        if gameState == GameState.wait1 {
            firstCardIndex = atIndex
            gameState = GameState.wait2
        } else {
            secondCardIndex = atIndex
            gameState = GameState.turnComplete
        }
    }
    
    func startNewTurn() {
        if cards[secondCardIndex!] == cards[firstCardIndex!] {
            cardStates[secondCardIndex!] = State.removed
            cardStates[firstCardIndex!] = State.removed
        } else {
            cardStates[secondCardIndex!] = State.hidden
            cardStates[firstCardIndex!] = State.hidden
        }
        gameState = checkForWin() ? GameState.over : GameState.wait1
    }

    func checkForWin() -> Bool {
        for s in cardStates {
            if s != State.removed {
                return false
            }
        }
        return true
    }
}
