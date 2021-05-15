//
//  AutoglyphView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/14/21.
//

import SwiftUI

let glyphPrefix = "data:text/plain;charset=utf-8,"

struct AutoglyphDrawing: Shape {
  
  
  private let cells : CGFloat = 64.0
  private let cellHalfPixels : CGFloat = 10.0
  private let cellPixels : CGFloat = 20.0
  
  let utf8 : String
  func path(in rect: CGRect) -> Path {
    
    let width: CGFloat = rect.width
    let pixel : CGFloat = width / (cells * cellPixels)
    return Path { path in
      
      // print(utf8)
      let strings =
        utf8
        .deletingPrefix(glyphPrefix)
        .replacingOccurrences(of: "%0A", with: "\n")
        //.replacingOccurrences(of: ".", with: " ")
        .split(separator: "\n")
      strings.enumerated().forEach { (rowIndex,str) in
        // print(str)
        
        let minY = CGFloat(rowIndex) * (cellPixels * pixel)
        let midY = minY + (cellHalfPixels * pixel)
        let maxY = minY + (cellPixels * pixel)
        
        str.enumerated().forEach { (charIndex,char) in
          // print(charIndex)
          
          let minX = CGFloat(charIndex) * (cellPixels * pixel)
          let midX = minX + (cellHalfPixels * pixel)
          let maxX = minX + (cellPixels * pixel)
          
          switch char {
          
          /*
           * The output of the 'tokenURI' function is a set of instructions to make a drawing.
           * Each symbol in the output corresponds to a cell, and there are 64x64 cells arranged in a square grid.
           * The drawing can be any size, and the pen's stroke width should be between 1/5th to 1/10th the size of a cell.
           * The drawing instructions for the nine different symbols are as follows:
           *
           *   .  Draw nothing in the cell.
           *   O  Draw a circle bounded by the cell.
           *   +  Draw centered lines vertically and horizontally the length of the cell.
           *   X  Draw diagonal lines connecting opposite corners of the cell.
           *   |  Draw a centered vertical line the length of the cell.
           *   -  Draw a centered horizontal line the length of the cell.
           *   \  Draw a line connecting the top left corner of the cell to the bottom right corner.
           *   /  Draw a line connecting the bottom left corner of teh cell to the top right corner.
           *   #  Fill in the cell completely.
           */
          
          case "O":
            path.move(to:CGPoint(x: midX, y: midY))
            path.addArc(
              center: CGPoint(x: midX, y: midY),
              radius: cellHalfPixels * pixel,
              startAngle:.degrees(0),
              endAngle:.degrees(360),
              clockwise: true)
          case "+":
            path.move(to:CGPoint(x: midX, y: minY))
            path.addLine(to: CGPoint(x:midX,y:maxY))
            
            path.move(to:CGPoint(x: minX, y: midY))
            path.addLine(to: CGPoint(x:maxX,y:midY))
            
          case "X":
            path.move(to:CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x:maxX,y:maxY))
            
            path.move(to:CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x:maxX,y:minY))
            
          case "|":
            path.move(to:CGPoint(x: midX, y: minY))
            path.addLine(to: CGPoint(x:midX,y:maxY))
            
          case "-":
            path.move(to:CGPoint(x: minX, y: midY))
            path.addLine(to: CGPoint(x:maxX,y:midY))
            
          case "\\":
            path.move(to:CGPoint(x: minX, y: minY))
            path.addLine(to: CGPoint(x:maxX,y:maxY))
            
          case "/":
            path.move(to:CGPoint(x: minX, y: maxY))
            path.addLine(to: CGPoint(x:maxX,y:minY))
            
          case "#":
            path.move(to:CGPoint(x: minX, y: minY))
            let rect = CGRect(x: minX, y: maxY, width: (cellPixels * pixel), height: (cellPixels * pixel))
            path.addRect(rect)
          case ".":
            break
          default:
            break
          }
        }
      }
    }
  }
}

struct AutoglyphText : View {
  let autoglyph : Media.Autoglyph?
  let width : CGFloat
  
  var body: some View {
    switch(autoglyph) {
    case .none:
      AutoglyphDrawing(utf8:String(repeating:String(repeating: ".", count: 64) + "\n",count:64))
        .stroke(Color.systemBackground)
        .frame(width: width, height: width)
        .padding()
    case .some(let text):
      AutoglyphDrawing(utf8:text.utf8)
        .stroke(Color.systemBackground)
        .frame(width: width, height: width)
        .padding()
    }
  }
}


struct AutoglyphView: View {
  
  @ObservedObject var autoglyph : ObservablePromise<Media.Autoglyph?>
  var samples : [String] // TODO Use
  var themeColor : Color
  var width : CGFloat
  var body: some View {
    VStack {
      ObservedPromiseView(
        data:autoglyph,
        progress:
          ZStack {
            AutoglyphDrawing(utf8:String(repeating:String(repeating: ".", count: 64) + "\n",count:64))
              .stroke(Color.systemBackground)
              .frame(width: width, height: width)
              .padding()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: Color.tertiarySystemBackground))
              .scaleEffect(2,anchor: .center)
          }) {
        AutoglyphText(autoglyph:$0,width: width)
          .background(themeColor)
      }
    }
    .background(themeColor)
  }
}

struct AutoglyphView_Previews: PreviewProvider {
  
  static var previews: some View {
    AutoglyphView(autoglyph:
                    ObservablePromise(resolved:Media.Autoglyph(utf8:"data:text/plain;charset=utf-8,.|.|.O..-.-.-.-.-.|.|.|.O.O.O.O..O.O.O.O.|.|.|.-.-.-.-.-..O.|.|.%0A|-.|.O|.O-.|..|.O-.O..|..-.O-.|..|.-O.-..|..O.-O.|..|.-O.|O.|.-|%0A..|-..|-.OO-..|...|..O-..O|..O-..-O..|O..-O..|...|..-OO.-|..-|..%0A||-...OO|....OO--...O|--...||-....-||...--|O...--OO....|OO...-||%0A..........O.OOOOO||-||--.-............-.--||-||OOOOO.O..........%0AOO.......-|||OO.......-|-|OOO......OOO|-|-.......OO|||-.......OO%0A.||O..--O..-||O..-|O..-||...-|O..O|-...||-..O|-..O||-..O--..O||.%0A..-O..-O.-O..|..|..-O.--O.-O..|..|..O-.O--.O-..|..|..O-.O-..O-..%0A-O.|..O.-.-..|.-O.|.-O.|.|..O.-..-.O..|.|.O-.|.O-.|..-.-.O..|.O-%0A.-O..-.-.|.|.-.|.|.O.O.|.O.O..-..-..O.O.|.O.O.|.|.-.|.|.-.-..O-.%0A-.O.O|.O-.|..-.O-.O.O|.O-.|-.-.OO.-.-|.-O.|O.O.-O.-..|.-O.|O.O.-%0A.|-..|-..|..|-..|-.O|..O|..O-..OO..-O..|O..|O.-|..-|..|..-|..-|.%0A-...O||....||.....||....O|-...OOOO...-|O....||.....||....||O...-%0A...OOO|||---.---.........OOOO||||||OOOO.........---.---|||OOO...%0A-||OOOO......--|-|OO.O.......-||||-.......O.OO|-|--......OOOO||-%0A...-O...-|O..-||O...|O...-|O..-||-..O|-...O|...O||-..O|-...O-...%0A-O.-O..|O.-|..-O.-O..|..-O..|O.--.O|..O-..|..O-.O-..|-.O|..O-.O-%0A.-..|.-..|.-..|.-..|....|....|....|....|....|..-.|..-.|..-.|..-.%0A|.|.|.|.|.O.|.O.O.O.O.|.O.O.O-O..O-O.O.O.|.O.O.O.O.|.O.|.|.|.|.|%0A.O..-.O-.O.O|.O..|..-.|-.|..-.O..O.-..|.-|.-..|..O.|O.O.-O.-..O.%0A|..O|..O-.O|...|..O-..|-..|..O|..|O..|..-|..-O..|...|O.-O..|O..|%0A..O||...OO|...OO|....O|-...O||....||O...-|O....|OO...|OO...||O..%0A||------..........||||||---..........---||||||..........------||%0A...--||-||OO.......---||||OOO......OOO||||---.......OO||-||--...%0AO....-|O..-|O...-|O...-|...-|O....O|-...|-...O|-...O|-..O|-....O%0A.-O.-|..|O..|O.-O..|..-|..|O.-O..O-.O|..|-..|..O-.O|..O|..|-.O-.%0AO.|..O.-..|.-O.|..O.|.-O.|.-O.|..|.O-.|.O-.|.O..|.O-.|..-.O..|.O%0A.O.|.O.O.O-O.O.O.....O.O-O-O........O-O-O.O.....O.O.O-O.O.O.|.O.%0AO-.|.O-.O..-.O..|.O-.|.O|.O..|.OO.|..O.|O.|.-O.|..O.-..O.-O.|.-O%0A..O-..|...-..|-.O|-.O|..O-..|..OO..|..-O..|O.-|O.-|..-...|..-O..%0AO|-...O|--..O||-..OO|....O|....OO....|O....|OO..-||O..--|O...-|O%0A..........OOO|||-...........OOOOOOOO...........-|||OOO..........%0A..........OOO|||-...........OOOOOOOO...........-|||OOO..........%0AO|-...O|--..O||-..OO|....O|....OO....|O....|OO..-||O..--|O...-|O%0A..O-..|...-..|-.O|-.O|..O-..|..OO..|..-O..|O.-|O.-|..-...|..-O..%0AO-.|.O-.O..-.O..|.O-.|.O|.O..|.OO.|..O.|O.|.-O.|..O.-..O.-O.|.-O%0A.O.|.O.O.O-O.O.O.....O.O-O-O........O-O-O.O.....O.O.O-O.O.O.|.O.%0AO.|..O.-..|.-O.|..O.|.-O.|.-O.|..|.O-.|.O-.|.O..|.O-.|..-.O..|.O%0A.-O.-|..|O..|O.-O..|..-|..|O.-O..O-.O|..|-..|..O-.O|..O|..|-.O-.%0AO....-|O..-|O...-|O...-|...-|O....O|-...|-...O|-...O|-..O|-....O%0A...--||-||OO.......---||||OOO......OOO||||---.......OO||-||--...%0A||------..........||||||---..........---||||||..........------||%0A..O||...OO|...OO|....O|-...O||....||O...-|O....|OO...|OO...||O..%0A|..O|..O-.O|...|..O-..|-..|..O|..|O..|..-|..-O..|...|O.-O..|O..|%0A.O..-.O-.O.O|.O..|..-.|-.|..-.O..O.-..|.-|.-..|..O.|O.O.-O.-..O.%0A|.|.|.|.|.O.|.O.O.O.O.|.O.O.O-O..O-O.O.O.|.O.O.O.O.|.O.|.|.|.|.|%0A.-..|.-..|.-..|.-..|....|....|....|....|....|..-.|..-.|..-.|..-.%0A-O.-O..|O.-|..-O.-O..|..-O..|O.--.O|..O-..|..O-.O-..|-.O|..O-.O-%0A...-O...-|O..-||O...|O...-|O..-||-..O|-...O|...O||-..O|-...O-...%0A-||OOOO......--|-|OO.O.......-||||-.......O.OO|-|--......OOOO||-%0A...OOO|||---.---.........OOOO||||||OOOO.........---.---|||OOO...%0A-...O||....||.....||....O|-...OOOO...-|O....||.....||....||O...-%0A.|-..|-..|..|-..|-.O|..O|..O-..OO..-O..|O..|O.-|..-|..|..-|..-|.%0A-.O.O|.O-.|..-.O-.O.O|.O-.|-.-.OO.-.-|.-O.|O.O.-O.-..|.-O.|O.O.-%0A.-O..-.-.|.|.-.|.|.O.O.|.O.O..-..-..O.O.|.O.O.|.|.-.|.|.-.-..O-.%0A-O.|..O.-.-..|.-O.|.-O.|.|..O.-..-.O..|.|.O-.|.O-.|..-.-.O..|.O-%0A..-O..-O.-O..|..|..-O.--O.-O..|..|..O-.O--.O-..|..|..O-.O-..O-..%0A.||O..--O..-||O..-|O..-||...-|O..O|-...||-..O|-..O||-..O--..O||.%0AOO.......-|||OO.......-|-|OOO......OOO|-|-.......OO|||-.......OO%0A..........O.OOOOO||-||--.-............-.--||-||OOOOO.O..........%0A||-...OO|....OO--...O|--...||-....-||...--|O...--OO....|OO...-||%0A..|-..|-.OO-..|...|..O-..O|..O-..-O..|O..-O..|...|..-OO.-|..-|..%0A|-.|.O|.O-.|..|.O-.O..|..-.O-.|..|.-O.-..|..O.-O.|..|.-O.|O.|.-|%0A.|.|.O..-.-.-.-.-.|.|.|.O.O.O.O..O.O.O.O.|.|.|.-.-.-.-.-..O.|.|.%0A")),
                  samples:SAMPLE_PUNKS,
                  themeColor:Color.secondary,
                  width:300)
  }
}
