import SwiftUI

private let tabletInk = Color(red: 0.23, green: 0.29, blue: 0.42)
private let tabletAccent = Color(red: 0.37, green: 0.43, blue: 0.72)

struct TabletPracticeView: View {
    @ObservedObject var store: PracticeStore
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 900 && geometry.size.width > geometry.size.height
            let padding: CGFloat = geometry.size.width < 600 ? 16 : 24
            VStack(spacing: 16) {
                header(compact: geometry.size.width < 500)
                if store.isFinished { results }
                else if wide {
                    HStack(spacing: 20) {
                        question.frame(maxWidth: .infinity, maxHeight: .infinity)
                        controls(keyHeight: min(78, max(54, (geometry.size.height - 290) / 4)))
                            .frame(width: min(440, geometry.size.width * 0.41))
                    }.frame(maxHeight: .infinity)
                } else {
                    VStack(spacing: 18) {
                        question.frame(maxWidth: .infinity, maxHeight: .infinity)
                        controls(keyHeight: min(72, max(48, (geometry.size.height - 460) / 4)))
                            .frame(maxWidth: 560)
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }.padding(padding)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(PracticeBackdrop())
                .foregroundStyle(tabletInk)
                .preferredColorScheme(.light)
                .sheet(isPresented: $store.showingHistory) { ContentView(store: store).historyView }
                .sheet(isPresented: $store.confirmingRestart) { ContentView(store: store).restartView }
                .sensoryFeedback(.selection, trigger: store.session.index)
        }
    }
    private func header(compact: Bool) -> some View {
        HStack(spacing: 10) {
            ArithmeticMark()
            if !compact { Text("口算练习").font(.system(size: 23, weight: .semibold, design: .rounded)) }
            Spacer(minLength: 8)
            Button { store.showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath").font(.system(size: 22)).frame(width: 24, height: 24) }
                .buttonStyle(PracticeActionStyle()).accessibilityLabel("练习记录")
            Button { store.requestRestart() } label: { Image(systemName: "arrow.counterclockwise").font(.system(size: 22)).frame(width: 24, height: 24) }
                .buttonStyle(PracticeActionStyle()).accessibilityLabel("重新开始")
        }
    }
    private var question: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center) {
                Text("\(store.session.index + 1) / \(store.questions.count)")
                    .font(.system(size: 23, weight: .medium, design: .rounded)).monospacedDigit()
                Spacer()
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Image(systemName: "stopwatch").font(.system(size: 20))
                        Text(PracticeStore.seconds(store.session.elapsed(at: context.date)))
                            .font(.system(size: 34, weight: .semibold, design: .rounded)).monospacedDigit()
                        Text("秒").font(.system(size: 17))
                    }.frame(width: 152, height: 68).practiceGlass(radius: 20, tint: .indigo.opacity(0.06))
                }
            }.foregroundStyle(tabletAccent)
            Spacer(minLength: 0)
            VStack(spacing: 16) {
                ForEach(Array(store.current.lines.enumerated()), id: \.offset) { _, line in
                    HStack(spacing: 5) {
                        ForEach(Array(line.enumerated()), id: \.offset) { _, part in
                            if let text = part.text {
                                Text(text).font(.system(size: store.current.plainText.count < 14 ? 48 : 30, weight: .medium, design: .rounded))
                            } else if let blank = part.blank {
                                Button { store.selectBlank(blank) } label: {
                                    Text(store.session.answers[store.session.index][blank].isEmpty ? " " : store.session.answers[store.session.index][blank])
                                        .font(.system(size: 37, weight: .medium, design: .rounded))
                                        .frame(minWidth: 60, minHeight: 66).padding(.horizontal, 3)
                                        .practiceGlass(radius: 13, tint: .indigo.opacity(0.05), interactive: true)
                                        .overlay(RoundedRectangle(cornerRadius: 13).stroke(store.session.activeBlank == blank ? tabletAccent : .clear, lineWidth: 2))
                                }.buttonStyle(.plain).foregroundStyle(tabletAccent).accessibilityLabel("第\(blank + 1)空")
                            }
                        }
                    }.lineLimit(2).minimumScaleFactor(0.55)
                }
            }.frame(maxWidth: .infinity)
            Spacer(minLength: 0)
        }.padding(22)
            .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.8), lineWidth: 1))
            .overlay(alignment: .bottom) {
                if !store.notice.isEmpty { Text(store.notice).font(.system(size: 17)).foregroundStyle(.orange).padding(12) }
            }
    }
    private func controls(keyHeight: CGFloat) -> some View {
        VStack(spacing: 16) {
            if let best = store.best {
                HStack {
                    Image(systemName: "trophy.fill").foregroundStyle(.orange)
                    Text("最快")
                    Spacer()
                    Text("\(PracticeStore.seconds(best.seconds)) 秒").monospacedDigit()
                }.font(.system(size: 19)).foregroundStyle(tabletAccent)
            }
            nearby
            let keys = store.comparison ? [">", "<", "="] : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "0", "delete"]
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                ForEach(keys, id: \.self) { key in
                    Button { store.input(key) } label: {
                        Group {
                            if key == "delete" { Image(systemName: "delete.left") }
                            else if key == "clear" { Image(systemName: "eraser") }
                            else { Text([">": "＞", "<": "＜", "=": "＝"][key] ?? key) }
                        }.font(.system(size: 33, weight: .semibold, design: .rounded))
                            .frame(maxWidth: .infinity).frame(height: store.comparison ? keyHeight * 1.35 : keyHeight)
                    }.buttonStyle(GlassKeyStyle(accent: key == "delete" || key == "clear"))
                        .accessibilityLabel(["delete": "删除一位", "clear": "清空本空", ">": "大于", "<": "小于", "=": "等于"][key] ?? key)
                }
            }.frame(height: keyHeight * 4 + 36).groupedGlass().animation(nil, value: store.comparison)
            HStack(spacing: 14) {
                Button { store.navigate(store.session.index - 1) } label: { Image(systemName: "chevron.left").frame(width: 26, height: 32) }
                    .buttonStyle(PracticeActionStyle()).disabled(store.session.index == 0).accessibilityLabel("上一题")
                Button { store.next() } label: {
                    HStack { Text(store.nextLabel); Image(systemName: "arrow.right") }
                        .font(.system(size: 22, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 32)
                }.buttonStyle(PracticeActionStyle(prominent: true))
            }
        }.padding(18)
            .background(.white.opacity(0.25), in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.8), lineWidth: 1))
    }
    private var nearby: some View {
        let count = min(5, store.questions.count)
        let start = max(0, min(store.session.index - 2, store.questions.count - count))
        return HStack(spacing: 8) {
            ForEach(start..<(start + count), id: \.self) { index in
                Button { store.navigate(index) } label: {
                    Text("\(index + 1)").font(.system(size: 21, weight: .medium, design: .rounded))
                        .frame(width: 44, height: 46)
                        .foregroundStyle(store.session.index == index ? .white : tabletAccent)
                        .background(store.session.index == index ? tabletAccent : .white.opacity(0.6), in: Circle())
                }.buttonStyle(.plain).accessibilityLabel("第\(index + 1)题")
            }
        }.frame(maxWidth: .infinity)
    }
    private var results: some View {
        let correct = store.session.correctCount(questions: store.questions)
        return ScrollView {
            VStack(spacing: 26) {
                Image(systemName: "star.circle.fill").font(.system(size: 68)).foregroundStyle(.orange)
                Text(correct == store.questions.count ? "全对！" : "完成！").font(.system(size: 36, weight: .bold))
                Text("\(PracticeStore.seconds(store.session.elapsed())) 秒").font(.system(size: 44, weight: .semibold, design: .rounded)).monospacedDigit()
                Text("答对 \(correct) / \(store.questions.count)").font(.system(size: 24))
                if store.session.isNewRecord { Label("新纪录！", systemImage: "trophy.fill").font(.title2).foregroundStyle(.orange) }
                Button("再练一次") { store.restart() }.font(.title2.bold()).buttonStyle(PracticeActionStyle(prominent: true))
                ForEach(store.questions.indices.filter { !store.session.isCorrect($0, questions: store.questions) }, id: \.self) { index in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(index + 1). \(store.questions[index].plainText)").font(.title3)
                        Text("\(store.session.answers[index].joined(separator: "，"))  →  \(store.questions[index].answers.joined(separator: "，"))").foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(18).background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding(24).frame(maxWidth: .infinity)
        }.foregroundStyle(tabletAccent)
    }
}
