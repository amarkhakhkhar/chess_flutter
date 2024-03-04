import 'package:chess_game/components/dead_piece.dart';
import 'package:chess_game/components/piece.dart';
import 'package:chess_game/components/square.dart';
import 'package:chess_game/constants/constant.dart';
import 'package:chess_game/helper/helper_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late List<List<ChessPiece?>> board;
  ChessPiece? selectedPiece;
  int selectedRow = -1;
  int selectedCol = -1;

  List<List<int>> validMoves = [];

  // Pieces killed
  List<ChessPiece> whitePiecesTaken = [];
  List<ChessPiece> blackPiecesTaken = [];

  // Turn changes 
  bool isWhiteTurn = true;

  // Intial king position for future reference for check mates
  List<int> whiteKingPosition = [7,4];
  List<int> blackKingPosition = [0,4];
  bool checkStatus = false;
  @override
  void initState() {
    super.initState();
    _intializeBoard();
  }

  void _intializeBoard() {
    // initialize with null
    List<List<ChessPiece?>> newBoard =
        List.generate(8, (index) => List.generate(8, (index) => null));

    // Place pawns
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
          type: ChessPieceType.pawn, isWhite: false, imagePath: pawnImagePath);
      newBoard[6][i] = ChessPiece(
          type: ChessPieceType.pawn, isWhite: true, imagePath: pawnImagePath);
    }
    // Place rooks
    newBoard[0][0] = ChessPiece(
        type: ChessPieceType.rook, isWhite: false, imagePath: rookImagePath);
    newBoard[0][7] = ChessPiece(
        type: ChessPieceType.rook, isWhite: false, imagePath: rookImagePath);
    newBoard[7][0] = ChessPiece(
        type: ChessPieceType.rook, isWhite: true, imagePath: rookImagePath);
    newBoard[7][7] = ChessPiece(
        type: ChessPieceType.rook, isWhite: true, imagePath: rookImagePath);

    // Place knights
    newBoard[0][1] = ChessPiece(
        type: ChessPieceType.knight,
        isWhite: false,
        imagePath: knightImagePath);
    newBoard[0][6] = ChessPiece(
        type: ChessPieceType.knight,
        isWhite: false,
        imagePath: knightImagePath);
    newBoard[7][1] = ChessPiece(
        type: ChessPieceType.knight, isWhite: true, imagePath: knightImagePath);
    newBoard[7][6] = ChessPiece(
        type: ChessPieceType.knight, isWhite: true, imagePath: knightImagePath);

    // Place bishops
    newBoard[0][2] = ChessPiece(
        type: ChessPieceType.bishop,
        isWhite: false,
        imagePath: bishopImagePath);
    newBoard[0][5] = ChessPiece(
        type: ChessPieceType.bishop,
        isWhite: false,
        imagePath: bishopImagePath);
    newBoard[7][2] = ChessPiece(
        type: ChessPieceType.bishop, isWhite: true, imagePath: bishopImagePath);
    newBoard[7][5] = ChessPiece(
        type: ChessPieceType.bishop, isWhite: true, imagePath: bishopImagePath);

    // Place Queens
    newBoard[0][3] = ChessPiece(
        type: ChessPieceType.queen, isWhite: false, imagePath: queenImagePath);
    newBoard[7][3] = ChessPiece(
        type: ChessPieceType.queen, isWhite: true, imagePath: queenImagePath);

    // Place Kings
    newBoard[0][4] = ChessPiece(
        type: ChessPieceType.king, isWhite: false, imagePath: kingImagePath);
    newBoard[7][4] = ChessPiece(
        type: ChessPieceType.king, isWhite: true, imagePath: kingImagePath);

    board = newBoard;
  }

  void pieceSelected(int row, int col) {
    setState(() {
      // no piece selected, first step
      if (selectedPiece == null && board[row][col] != null) {

        if(board[row][col]!.isWhite == isWhiteTurn){

        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
        }
      }

      // piece already selected but user selects another piece
      else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece!.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
      }
      // piece is selected and valid move is selected
      else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }

      validMoves =
          calculateRealValidMoves(selectedRow, selectedCol, selectedPiece,true);
    });
  }

  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    if (piece == null) {
      return [];
    }

    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // forward 1 space
        if (isInBoard(row + direction, col) &&
            board[direction + row][col] == null) {
          candidateMoves.add([row + direction, col]);
        }
        
        // forward 2 space
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2*direction , col) &&
              board[row + 2*direction][col] == null &&
              board[direction + row][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

        // diagonal to kill
        if (isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col - 1]);
        }

        if (isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite)
             {
          candidateMoves.add([row + direction, col + 1]);
        }

        break;
      case ChessPieceType.rook:
        // horizontal and vertical directions
        var directions = [
          [-1, 0], //up
          [1, 0], //down
          [0, -1], //left
          [0, 1] //right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.knight:
        var knightMoves = [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1]
        ];

        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];

          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]);
            }
            continue;
          }
          candidateMoves.add([newRow, newCol]);
        }

        break;
      case ChessPieceType.bishop:
        var directions = [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];

            if (!isInBoard(newRow, newCol)) {
              break;
            }

            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }

            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.queen:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }

            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }

            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }

        break;
      case ChessPieceType.king:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1]
        ];
        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1]; 
          if (!isInBoard(newRow, newCol)) {
            continue;
          }

          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]);
            }
            continue;
          }

          candidateMoves.add([newRow, newCol]);
        }

        break;
      default:
    }

    return candidateMoves;
  }

  List<List<int>> calculateRealValidMoves(int row, int col, ChessPiece? piece, bool checkSimulation){
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRawValidMoves(row, col, piece);

    // after generating all candidateMoves and remove which will result in king check

    if(checkSimulation){
      for( var move in candidateMoves){
        int endRow = move[0];
        int endCol = move[1];

        // simulating and checking 
        if(simulatedMoveIsSafe(piece!, row, col, endRow,endCol)){
          realValidMoves.add(move);
        }
      }
    }
    else{
          realValidMoves = candidateMoves;
        }
    return realValidMoves;
  }

  void movePiece(int newRow, int newCol) {
    // if new piece is enemy add to list
    if (board[newRow][newCol] != null) {
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whitePiecesTaken.add(capturedPiece);
      } else {
        blackPiecesTaken.add(capturedPiece);
      }
    }

    // check if piece being move is king and is under checked 
    if(selectedPiece!.type == ChessPieceType.king){
      if(selectedPiece!.isWhite){
        whiteKingPosition = [newRow, newCol];
      }else{
        blackKingPosition = [ newRow, newCol];
      }
    }

    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    if(isKingInCheck(!isWhiteTurn)){
      checkStatus = true;
    }else{
      checkStatus = false;
    }

    setState(() {
      selectedPiece = null;
      selectedCol = -1;
      selectedRow = -1;
    });

    // check for checkmate
    if(isCheckMate(isWhiteTurn)){
      showDialog(context: context, builder: (context)=> AlertDialog(
        title:const Text( "CHECK MATE!"),
        actions: [
          TextButton(onPressed: resetGame, child: const Text("Play Again!"))
        ],
        ),
        );
    }

    // change turn 
    isWhiteTurn = !isWhiteTurn;
  }

  bool isKingInCheck(bool isWhiteKing){

    List<int> kingPostion = isWhiteKing ? whiteKingPosition : blackKingPosition;

    for(int i =0;i< 8;i++){
      for(int j =0 ; j<8;j++){
        // skip empty and same color positions 
        if(board[i][j] == null || board[i][j]!.isWhite == isWhiteKing){
          continue;
        }

        List<List<int>> pieceValidMoves = calculateRealValidMoves(i, j, board[i][j],false);

        // compare position of king to valid moves 
        if(pieceValidMoves.any((element) => element[0] == kingPostion[0] && element[1] == kingPostion[1])){
          return true;
        }
      }
    }
    return false;
  }

  // simulation future move to see it's safe
  bool simulatedMoveIsSafe(ChessPiece piece, int startRow, int startCol, int endRow, int endCol){
    // saving current state 
    ChessPiece? originalDestinationPlace = board[endRow][endCol];

    // if piece is king save it's curr pos and update to new one
    List<int>? originalKingPosition;
    if(piece.type == ChessPieceType.king){
      originalKingPosition = piece.isWhite ? whiteKingPosition : blackKingPosition;

    if(piece.isWhite){
      whiteKingPosition = [endRow,endCol];
    }else{
      blackKingPosition = [endRow, endCol];
    }
    }

    // simulate 
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // check king status 
    bool kingInCheck = isKingInCheck(piece.isWhite);
    
    // restore to original
   board[startRow][startCol] = piece;
   board[endRow][endCol] = originalDestinationPlace;

    // if piece was king, restore to original pos     
    if(piece.type == ChessPieceType.king){
      if(piece.isWhite){
        whiteKingPosition = originalKingPosition!;
      }else{
        blackKingPosition = originalKingPosition!;
      }
    }
    return !kingInCheck;
  } 
  
  bool isCheckMate(bool isWhiteKing){
    // if not in check not checkmate 
    if(!isKingInCheck(isWhiteKing)){
      return false;
    }

    // any legal move for any no checkmate 
    for(int i=0;i<8;i++){
      for(int j=0;j<8;j++){
        if(board[i][j]==null || board[i][j]!.isWhite != isWhiteKing){
          continue;
        }

        List<List<int>> pieceValidMoves = calculateRealValidMoves(i, j, board[i][j], true );

        if(pieceValidMoves.isNotEmpty){
          return false;
        }
      }
    }

    // if none of moves are available, check mate 
    return true;
  }

  void resetGame(){
    Navigator.pop(context);
    _intializeBoard();
    checkStatus=false;
    whitePiecesTaken.clear();
    blackPiecesTaken.clear();
      blackKingPosition = [0,4];
      whiteKingPosition = [7,4];
      isWhiteTurn = true;
    setState(() {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // White piece taken
          Expanded(
              child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: whitePiecesTaken.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8),
                  itemBuilder: (context, index) => DeadPiece(
                      imagePath: whitePiecesTaken[index].imagePath,
                      isWhite: true))),

          // Game Status 
          Text(
            checkStatus ? "CHECK" : ""
          ),


          // Chess board
          Expanded(
            flex: 3,
            child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 8 * 8,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8),
                itemBuilder: (context, index) {
                  int row = index ~/ 8;
                  int col = index % 8;

                  bool isSelected = selectedRow == row && selectedCol == col;

                  bool isValidMove = false;
                  for (var position in validMoves) {
                    if (position[0] == row && position[1] == col) {
                      isValidMove = true;
                    }
                  }
                  return Square(
                    isWhite: isWhite(index),
                    piece: board[row][col],
                    isSelected: isSelected,
                    onTap: () => pieceSelected(row, col),
                    isValidMove: isValidMove,
                  );
                }),
          ),

          // Black pieces taken
          Expanded(
              child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: blackPiecesTaken.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8),
                  itemBuilder: (context, index) => DeadPiece(
                      imagePath: blackPiecesTaken[index].imagePath,
                      isWhite: false))),
        ],
      ),
    );
  }
}
