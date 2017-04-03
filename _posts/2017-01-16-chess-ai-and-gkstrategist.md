---
title: "chess, ai, and gkstrategist"
date: 2017-01-16
---

<h2><a href="http://evandekhayser.com/2017/01/16/chess-ai-and-gkstrategist" class="title">chess, ai, and gkstrategist</a></h2>
<h5>16 Jan 2017</h5>

For the past several months, I have been developing a variation of chess using Apple's GameplayKit. Specifically, I am trying to use GKStrategist to create an AI opponent for single player.

At the moment, GameplayKit comes with two strategists: GKMinMaxStrategist and GKMonteCarloStrategist. Both have their strengths, which the documentation covers well. But the deficiencies of each make them both unusable in a chess game.

This project is meant as a learning experience, so I have been trying to learn exactly what happens under the hood of these two classes. What better way is there to learn that by recreating them?

### MonteCarloStrategist

The Monte Carlo strategy focuses on win-loss conditions only, so it was not even worth considering for a game as long and drawn out as chess. It evaluates moves based on how likely they are to lead to a win or a loss. Rather than evaluating every move, it chooses several random moves and sees what happens in the future. If no move is found quickly, it moves onto another move.

Even though this makes no sense for a game like chess (tic-tac-toe would be a more fitting application), I tried it out for the sake of science. For most of the game, the AI makes seemingly random moves (probably because they are random…). The AI finally stops making random moves when you put it into check, after which the king runs for its life.

Because of the complex nature of chess, Monte Carlo is not the right place to look for an AI.

### MinMaxStrategist

This was the first strategist made available to developers at WWDC 2015. Minmax is also one of the leading techniques used by chess software, so it is clearly worth strong consideration. Without including memory optimizations Apple’s provided class probably uses, here is the source code of a Minmax strategist I developed for my game:

```swift
import GameplayKit

class MinMaxStrategist: NSObject, GKStrategist {

  var gameModel: GKGameModel?
  var randomSource: GKRandomSource?
  var maxDepth: Int = 3
  var activePlayer: GKGameModelPlayer!

  func bestMoveForActivePlayer() → GKGameModelUpdate? {
    activePlayer = gameModel?.activePlayer
    guard let moves = gameModel!.gameModelUpdate(for: activePlayer) as? [Move] else { return nil }
    moves.forEach{ (move) in
      let modelCopy = gameModel!.copy(with: nil) as! GameModel
      modelCopy.apply(move)
      move.value = minmax(model: modelCopy, depth: maxDepth, maximizing: true)
    }
    let movesSortedByStrength = moves.sorted{ (m1, m2) → Bool in
      m1.value > m2.value
    }
    return movesSortedByStrength.first
  }

  func minmax(model: GKGameModel, depth: Int, maximizing: Bool) → Int {
    if depth == 0 || model.isLoss(for: activePlayer) || model.isWin(for: activePlayer) {
      return board.score(for: activePlayer)
    }

    if maximizing {
      var bestValue = Int.min
      for move in model.gameModelUpdates(for: model.activePlayer!) as! [Move] {
        let modelCopy = model.copy(with: nil) as! Board
        modelCopy.apply(move)
        let value = minmax(model: modelCopy, depth: depth - 1, maximizing: false)
        bestValue = max(bestValue, v)
      }
      return bestValue
    } else {
      var bestValue = Int.max
      for move in model.gameModelUpdates(for: model.activePlayer!) as! [Move] {
        let modelCopy = model.copy(with: nil) as! Board
        modelCopy.apply(move)
        let value = minmax(model: modelCopy, depth: depth - 1, maximizing: true)
        bestValue = min(bestValue, v)
      }
      return bestValue
    }
  }
}
```

Minmax assumes that for every move, each player will do what they can to improve their chance of success. It goes through every possible permutation of moves until it reaches a certain depth, and rates each move according to its future consequences (or, if the move is the terminal node, by a scoring function you provide).

By assuming that a player would not intentionally make a harmful move, Minmax recognizes which moves the opponent would take and which the opponent would not. The opponent would not, for example, march their king into enemy lines.

One difficulty with Minmax is providing the aforementioned scoring function. How do you rank a chess board? One approach would be assigning different pieces different values (pawn = 5, knight = 15, queen = 100, etc.) and finding the net value of a board. You can also add a multiplier to where on the board a piece is located: a pawn that is one space away from promotion is worth more than a pawn in its initial position.

Another critical issue with Minmax is that it is exhaustive. The first move of a chess game has 20 moves; the second move of a chess game has 20 moves. Just looking at those two moves, you already have 400 game positions to score (which may not be very efficient itself). Look ahead one more move and you already have upwards of 8,000 moves. One more? Have fun with 160,000 boards. iPhones are fast, but they aren’t that fast.

How can this be improved? Alpha-Beta Pruning.

### AlphaBetaStrategist

~~I do not believe GKMinMaxStrategist uses Alpha-Beta pruning because the documentation makes no mention of it. If I get the chance to attend WWDC 2017, I will definitely reach out to an Apple engineer.~~

*Update:* GKMinMaxStrategist likely does use this technique. I timed the class implemented below, and I timed GKMinMaxStrategist, and Apple's version runs faster. My best guess, they use Alpha-Beta pruning as well as other optimizations. If I can go to WWDC this year, I still will talk to an Apple engineer

The code for the AlphaBetaStrategist is the same as MinMaxStrategist, except for these changes:

```swift
move.value = minmax(model: modelCopy, depth: maxDepth, maximizing: true)
```
becomes

```swift
move.value = alphabeta(board: boardCopy, depth: maxDepth, alpha: Int.min, beta: Int.max, maximizing: true)
```

Also, the minimax function is replaced by the following:

```swift
func alphabeta(model: GKGameModel, depth: Int, alpha: Int, beta: Int, maximizing: Bool) → Int {
  var alpha = alpha
  var beta = beta
  if depth == 0 || model.isLoss(for: activePlayer) || model.isWin(for: activePlayer) {
    return board.score(for: activePlayer)
  }

  if maximizingPlayer {
    for move in model.gameModelUpdates(for: model.activePlayer!) as! [Move] {
      let modelCopy = model.copy(with: nil) as! Board
      modelCopy.apply(move)
      let value = alphabeta(model: modelCopy, depth: depth - 1, alpha: alpha, beta: beta, maximizing: false)
      if value > alpha {
        alpha = result
      }
      if alpha >= beta {
        return alpha
      }
    }
    return alpha
  } else {
    for move in model.gameModelUpdates(for: model.activePlayer!) as! [Move] {
      let modelCopy = model.copy(with: nil) as! Board
      modelCopy.apply(move)
      let value = alphabeta(model: modelCopy, depth: depth - 1, alpha: alpha, beta: beta, maximizing: true)
      if result < beta {
        beta = result
      }
      if beta <= alpha{
        return beta
      }
    }
    return beta
  }
}
```

I was able to understand Alpha-Beta pruning enough to make this code functional, but I don’t think I could effectively explain it to others. I must defer to [Wikipedia](https://en.wikipedia.org/wiki/Alpha–beta_pruning).

Without going into specifics, this algorithm figures out which branches do not need to be evaluated based on the highest score of previously evaluated branches (alpha) and the lowest score of previously evaluated branches (beta). There are plenty of college resources that will you can look at online (I recommend Cornell or UPenn’s resources, especially).

### More?

There is always more. I am currently using the Alpha-Beta strategist in my game, which requires some tweaking to make the scoring function work better. I’m also looking for places to make this algorithm more efficient, as time constraints still force me to only look 2 or 3 moves deep. I would like to be able to move that up to 4 or 5.

Hopefully you were able to take something away from this. This has all been a lot of fun to research.
