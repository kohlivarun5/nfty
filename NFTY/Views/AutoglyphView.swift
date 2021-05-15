//
//  AutoglyphView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/14/21.
//

import SwiftUI

let glyphPrefix = "data:text/plain;charset=utf-8,"

struct AutoGlyph: View {
  let utf8 : String
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        var width: CGFloat = min(geometry.size.width, geometry.size.height)
        let height = width
        path.move(
          to: CGPoint(
            x: width * 0.95,
            y: height * (0.20 + HexagonParameters.adjustment)
          )
        )
        
        HexagonParameters.segments.forEach { segment in
          path.addLine(
            to: CGPoint(
              x: width * segment.line.x,
              y: height * segment.line.y
            )
          )
          
          path.addQuadCurve(
            to: CGPoint(
              x: width * segment.curve.x,
              y: height * segment.curve.y
            ),
            control: CGPoint(
              x: width * segment.control.x,
              y: height * segment.control.y
            )
          )
        }
      }
      .fill(Color.black)
    }
  }
}

struct AutoGlyphGeaometry: View {
  private let cells = 64.0
  private let cellPixels = 10.0
  
  let utf8 : String
  var body: some View {
    GeometryReader { geometry in
      Path { path in
        let width: CGFloat = min(geometry.size.width, geometry.size.height)
        let height = width
        let pixel = Double(width.remainder(dividingBy: (CGFloat(cells * cellPixels))))
        
        let strings = utf8.split(separator: "\n")
        strings.enumerated().forEach { (rowIndex,str) in
          
          let rowMinY = rowIndex * cellPixels * pixel
          
          str.enumerated().forEach { (charIndex,char) in
            
            let cellMinX = CGFloat(charIndex * cellPixels * pixel)
            
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
              path.addArc(center: CGPoint(x: cellMinX + (pixel * cellPixels/2), y: rowMinY * (pixel * cellPixels/2), radius: (pixel * cellPixels/2), startAngle: 0, endAngle: 360)
            case "+":
              path.move(to: CGPoint(x: cellMinX + (pixel * cellPixels/2),y: cellMinY))
              path.addLine(to: CGPoint(x: cellMinX + (pixel * cellPixels/2), y: cellMinY + (pixel * cellPixels))
              
              path.move(to: CGPoint(x: cellMinX,y: cellMinY + (pixel * cellPixels/2)))
              path.addLine(to: CGPoint(x: cellMinX + (pixel * cellPixels), y: cellMinY + (pixel * cellPixels/2)))
              
            case "+":
              path.move(to: CGPoint(x: cellMinX + (pixel * cellPixels/2),y: cellMinY))
              path.addLine(to: CGPoint(x: cellMinX + (pixel * cellPixels/2), y: cellMinY + (pixel * cellPixels))
                           
                           path.move(to: CGPoint(x: cellMinX,y: cellMinY + (pixel * cellPixels/2)))
                           path.addLine(to: CGPoint(x: cellMinX + (pixel * cellPixels), y: cellMinY + (pixel * cellPixels/2)))
              
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
}

struct AutoglyphText : View {
  let autoglyph : Media.Autoglyph?
  var fontSize : CGFloat
  
  var body: some View {
    switch(autoglyph) {
    case .none:
      Text(String(repeating: "\n", count: 64))
        .font(.system(size:fontSize, design: .monospaced))
        .foregroundColor(Color.systemBackground)
        .padding()
    case .some(let text):
      AutoGlyphGeaometry(
      utf8:
        text.utf8
          .deletingPrefix(glyphPrefix)
          .replacingOccurrences(of: "%0A", with: "\n")
          .replacingOccurrences(of: ".", with: " ")
          .split(separator:"\n"))
      .foregroundColor(Color.systemBackground)
      .padding()
    }
  }
}


struct AutoglyphView: View {
  
  @ObservedObject var autoglyph : ObservablePromise<Media.Autoglyph?>
  var samples : [String] // TODO Use
  var themeColor : Color
  var fontSize : CGFloat
  var body: some View {
    VStack {
      ObservedPromiseView(
        data:autoglyph,
        progress:
          ZStack {
            Text(String(repeating: "\n", count: 64))
              .font(.system(size:fontSize, design: .monospaced))
              .foregroundColor(Color.systemBackground)
              .padding()
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: Color.tertiarySystemBackground))
              .scaleEffect(2,anchor: .center)
          }) {
        AutoglyphText(autoglyph:$0,fontSize: fontSize)
          .background(Color.label)
      }
    }
    .background(themeColor)
  }
}

struct AutoglyphView_Previews: PreviewProvider {
  
  static var previews: some View {
    AutoglyphView(autoglyph:
                    ObservablePromise(resolved:Media.Autoglyph(utf8:"string :  data:text/plain;charset=utf-8.|.|.O..-.-.-.-.-.|.|.|.O.O.O.O..O.O.O.O.|.|.|.-.-.-.-.-..O.|.|.%0A|-.|.O|.O-.|..|.O-.O..|..-.O-.|..|.-O.-..|..O.-O.|..|.-O.|O.|.-|%0A..|-..|-.OO-..|...|..O-..O|..O-..-O..|O..-O..|...|..-OO.-|..-|..%0A||-...OO|....OO--...O|--...||-....-||...--|O...--OO....|OO...-||%0A..........O.OOOOO||-||--.-............-.--||-||OOOOO.O..........%0AOO.......-|||OO.......-|-|OOO......OOO|-|-.......OO|||-.......OO%0A.||O..--O..-||O..-|O..-||...-|O..O|-...||-..O|-..O||-..O--..O||.%0A..-O..-O.-O..|..|..-O.--O.-O..|..|..O-.O--.O-..|..|..O-.O-..O-..%0A-O.|..O.-.-..|.-O.|.-O.|.|..O.-..-.O..|.|.O-.|.O-.|..-.-.O..|.O-%0A.-O..-.-.|.|.-.|.|.O.O.|.O.O..-..-..O.O.|.O.O.|.|.-.|.|.-.-..O-.%0A-.O.O|.O-.|..-.O-.O.O|.O-.|-.-.OO.-.-|.-O.|O.O.-O.-..|.-O.|O.O.-%0A.|-..|-..|..|-..|-.O|..O|..O-..OO..-O..|O..|O.-|..-|..|..-|..-|.%0A-...O||....||.....||....O|-...OOOO...-|O....||.....||....||O...-%0A...OOO|||---.---.........OOOO||||||OOOO.........---.---|||OOO...%0A-||OOOO......--|-|OO.O.......-||||-.......O.OO|-|--......OOOO||-%0A...-O...-|O..-||O...|O...-|O..-||-..O|-...O|...O||-..O|-...O-...%0A-O.-O..|O.-|..-O.-O..|..-O..|O.--.O|..O-..|..O-.O-..|-.O|..O-.O-%0A.-..|.-..|.-..|.-..|....|....|....|....|....|..-.|..-.|..-.|..-.%0A|.|.|.|.|.O.|.O.O.O.O.|.O.O.O-O..O-O.O.O.|.O.O.O.O.|.O.|.|.|.|.|%0A.O..-.O-.O.O|.O..|..-.|-.|..-.O..O.-..|.-|.-..|..O.|O.O.-O.-..O.%0A|..O|..O-.O|...|..O-..|-..|..O|..|O..|..-|..-O..|...|O.-O..|O..|%0A..O||...OO|...OO|....O|-...O||....||O...-|O....|OO...|OO...||O..%0A||------..........||||||---..........---||||||..........------||%0A...--||-||OO.......---||||OOO......OOO||||---.......OO||-||--...%0AO....-|O..-|O...-|O...-|...-|O....O|-...|-...O|-...O|-..O|-....O%0A.-O.-|..|O..|O.-O..|..-|..|O.-O..O-.O|..|-..|..O-.O|..O|..|-.O-.%0AO.|..O.-..|.-O.|..O.|.-O.|.-O.|..|.O-.|.O-.|.O..|.O-.|..-.O..|.O%0A.O.|.O.O.O-O.O.O.....O.O-O-O........O-O-O.O.....O.O.O-O.O.O.|.O.%0AO-.|.O-.O..-.O..|.O-.|.O|.O..|.OO.|..O.|O.|.-O.|..O.-..O.-O.|.-O%0A..O-..|...-..|-.O|-.O|..O-..|..OO..|..-O..|O.-|O.-|..-...|..-O..%0AO|-...O|--..O||-..OO|....O|....OO....|O....|OO..-||O..--|O...-|O%0A..........OOO|||-...........OOOOOOOO...........-|||OOO..........%0A..........OOO|||-...........OOOOOOOO...........-|||OOO..........%0AO|-...O|--..O||-..OO|....O|....OO....|O....|OO..-||O..--|O...-|O%0A..O-..|...-..|-.O|-.O|..O-..|..OO..|..-O..|O.-|O.-|..-...|..-O..%0AO-.|.O-.O..-.O..|.O-.|.O|.O..|.OO.|..O.|O.|.-O.|..O.-..O.-O.|.-O%0A.O.|.O.O.O-O.O.O.....O.O-O-O........O-O-O.O.....O.O.O-O.O.O.|.O.%0AO.|..O.-..|.-O.|..O.|.-O.|.-O.|..|.O-.|.O-.|.O..|.O-.|..-.O..|.O%0A.-O.-|..|O..|O.-O..|..-|..|O.-O..O-.O|..|-..|..O-.O|..O|..|-.O-.%0AO....-|O..-|O...-|O...-|...-|O....O|-...|-...O|-...O|-..O|-....O%0A...--||-||OO.......---||||OOO......OOO||||---.......OO||-||--...%0A||------..........||||||---..........---||||||..........------||%0A..O||...OO|...OO|....O|-...O||....||O...-|O....|OO...|OO...||O..%0A|..O|..O-.O|...|..O-..|-..|..O|..|O..|..-|..-O..|...|O.-O..|O..|%0A.O..-.O-.O.O|.O..|..-.|-.|..-.O..O.-..|.-|.-..|..O.|O.O.-O.-..O.%0A|.|.|.|.|.O.|.O.O.O.O.|.O.O.O-O..O-O.O.O.|.O.O.O.O.|.O.|.|.|.|.|%0A.-..|.-..|.-..|.-..|....|....|....|....|....|..-.|..-.|..-.|..-.%0A-O.-O..|O.-|..-O.-O..|..-O..|O.--.O|..O-..|..O-.O-..|-.O|..O-.O-%0A...-O...-|O..-||O...|O...-|O..-||-..O|-...O|...O||-..O|-...O-...%0A-||OOOO......--|-|OO.O.......-||||-.......O.OO|-|--......OOOO||-%0A...OOO|||---.---.........OOOO||||||OOOO.........---.---|||OOO...%0A-...O||....||.....||....O|-...OOOO...-|O....||.....||....||O...-%0A.|-..|-..|..|-..|-.O|..O|..O-..OO..-O..|O..|O.-|..-|..|..-|..-|.%0A-.O.O|.O-.|..-.O-.O.O|.O-.|-.-.OO.-.-|.-O.|O.O.-O.-..|.-O.|O.O.-%0A.-O..-.-.|.|.-.|.|.O.O.|.O.O..-..-..O.O.|.O.O.|.|.-.|.|.-.-..O-.%0A-O.|..O.-.-..|.-O.|.-O.|.|..O.-..-.O..|.|.O-.|.O-.|..-.-.O..|.O-%0A..-O..-O.-O..|..|..-O.--O.-O..|..|..O-.O--.O-..|..|..O-.O-..O-..%0A.||O..--O..-||O..-|O..-||...-|O..O|-...||-..O|-..O||-..O--..O||.%0AOO.......-|||OO.......-|-|OOO......OOO|-|-.......OO|||-.......OO%0A..........O.OOOOO||-||--.-............-.--||-||OOOOO.O..........%0A||-...OO|....OO--...O|--...||-....-||...--|O...--OO....|OO...-||%0A..|-..|-.OO-..|...|..O-..O|..O-..-O..|O..-O..|...|..-OO.-|..-|..%0A|-.|.O|.O-.|..|.O-.O..|..-.O-.|..|.-O.-..|..O.-O.|..|.-O.|O.|.-|%0A.|.|.O..-.-.-.-.-.|.|.|.O.O.O.O..O.O.O.O.|.|.|.-.-.-.-.-..O.|.|.%0A")),
                  samples:SAMPLE_PUNKS,
                  themeColor:Color.secondary,
                  fontSize:6)
  }
}
