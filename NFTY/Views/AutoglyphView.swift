//
//  AutoglyphView.swift
//  NFTY
//
//  Created by Varun Kohli on 5/14/21.
//

import SwiftUI

let glyphPrefix = "data:text/plain;charset=utf-8,"

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
      Text(
        text.utf8
          .deletingPrefix(glyphPrefix)
          .replacingOccurrences(of: "%0A", with: "\n")
          .replacingOccurrences(of: ".", with: " ")
      )
      .font(.system(size:fontSize, design: .monospaced))
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
