import SwiftUI
#if canImport(PracticeCore)
import PracticeCore
#endif

private let ink = Color(red: 0.23, green: 0.29, blue: 0.42)
private let purple = Color(red: 0.37, green: 0.43, blue: 0.72)
private let mint = Color(red: 0.40, green: 0.67, blue: 0.66)

struct ContentView: View {
    @ObservedObject var store: PracticeStore
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 13) {
                ArithmeticMark()
                if store.isReview {
                    Button { store.leaveReview() } label: { Image(systemName: "arrow.uturn.backward") }.buttonStyle(PracticeActionStyle()).accessibilityLabel("返回整套练习")
                }
                Text(store.isReview ? "错题练习" : "口算练习").font(.system(size: 22, weight: .semibold, design: .rounded))
                Spacer()
                Button { store.showingHistory = true } label: { Image(systemName: "clock.arrow.circlepath").font(.title3) }
                    .buttonStyle(PracticeActionStyle()).accessibilityLabel("练习记录")
                Button { store.requestRestart() } label: { Image(systemName: "arrow.counterclockwise").font(.title3) }
                    .buttonStyle(PracticeActionStyle()).accessibilityLabel("重新开始")
            }.foregroundStyle(ink)
            Group {
                if store.isFinished { resultView } else { practiceView }
            }
            .background(.white.opacity(0.56), in: RoundedRectangle(cornerRadius: 26))
            .overlay(RoundedRectangle(cornerRadius: 26).stroke(.white.opacity(0.85), lineWidth: 1))
            .shadow(color: purple.opacity(0.07), radius: 25, y: 12)
            if store.persistenceWarning {
                Text("记录未能保存").font(.callout).foregroundStyle(.orange)
            }
        }
        .padding(24)
        .background(PracticeBackdrop())
        .foregroundStyle(ink)
        .preferredColorScheme(.light)
        #if os(macOS)
        .background(KeyboardInput(enabled: store.keyboardEnabled, input: store.input, next: store.next).frame(width: 0, height: 0))
        #endif
        .sheet(isPresented: $store.showingHistory) { historyView }
        .sheet(isPresented: $store.confirmingRestart) { restartView }

    }

    private var practiceView: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Text("\(store.session.index + 1) / \(store.questions.count)")
                        .font(.system(size: 24, weight: .medium, design: .rounded)).monospacedDigit().foregroundStyle(purple)
                        .accessibilityLabel("第\(store.session.index + 1)题，共\(store.questions.count)题")
                    Spacer()
                    timerView
                }
                Spacer(minLength: 15)
                questionView
                    .frame(maxWidth: .infinity, minHeight: 240, maxHeight: 240)
                    .accessibilityElement(children: .contain)
                Spacer(minLength: 15)
            }.padding(28).frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    if !store.notice.isEmpty {
                        Text(store.notice).font(.system(size: 18)).foregroundStyle(.orange).padding(.bottom, 28)
                    }
                }
            answerPanel.frame(width: 366).padding(22)
                .background(.white.opacity(0.22), in: RoundedRectangle(cornerRadius: 23))
                .overlay(RoundedRectangle(cornerRadius: 23).stroke(.white.opacity(0.75), lineWidth: 1))
                .padding(12)
        }
    }

    private var timerView: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { context in
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "stopwatch").font(.system(size: 21)).foregroundStyle(purple.opacity(0.7))
                Text(PracticeStore.seconds(store.session.elapsed(at: context.date)))
                    .font(.system(size: 40, weight: .semibold, design: .rounded)).monospacedDigit()
                Text("秒").font(.system(size: 18))
            }.foregroundStyle(purple).frame(width: 200, height: 88)
                .practiceGlass(radius: 22, tint: .indigo.opacity(0.06))

        }
    }

    private var questionView: some View {
        VStack(spacing: 20) {
            ForEach(Array(store.current.lines.enumerated()), id: \.offset) { _, parts in
                let instruction = parts.allSatisfy { $0.blank == nil }
                HStack(spacing: 5) {
                    ForEach(Array(parts.enumerated()), id: \.offset) { _, part in
                        if let text = part.text {
                            Text(text).font(instruction ? .system(size: 22) : .system(size: store.current.plainText.count < 14 ? 52 : 36, weight: .medium, design: .rounded)).foregroundStyle(instruction ? Color.secondary : ink)
                        } else if let blank = part.blank {
                            Button { store.selectBlank(blank) } label: {
                                Text(store.session.answers[store.session.index][blank].isEmpty ? " " : store.session.answers[store.session.index][blank])
                                    .font(.system(size: 40, weight: .medium, design: .rounded))
                                    .frame(minWidth: 64, minHeight: 70)
                                    .padding(.horizontal, 3)
                                    .practiceGlass(radius: 13, tint: store.session.activeBlank == blank ? .indigo.opacity(0.09) : .white.opacity(0.3), interactive: true)
                                    .overlay(RoundedRectangle(cornerRadius: 13).stroke(store.session.activeBlank == blank ? purple.opacity(0.8) : .clear, lineWidth: 1.5))
                            }.buttonStyle(.plain).foregroundStyle(purple).accessibilityLabel("第\(blank + 1)空").accessibilityValue(store.session.answers[store.session.index][blank])
                        }
                    }
                }.minimumScaleFactor(0.65).lineLimit(2)
            }
        }
    }

    private var answerPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            Spacer(minLength: 0)
            if let best = store.best {
                HStack(spacing: 10) {
                    Image(systemName: "trophy.fill").foregroundStyle(.orange)
                    Text("最快").foregroundStyle(.secondary)
                    Spacer()
                    Text("\(PracticeStore.seconds(best.seconds)) 秒").monospacedDigit().foregroundStyle(purple)
                }.font(.system(size: 20, weight: .medium, design: .rounded)).padding(.bottom, 12)
            }
            nearbyQuestions
            keypad
            HStack {
                Button { store.navigate(store.session.index - 1) } label: { Image(systemName: "chevron.left").frame(height: 22) }.buttonStyle(PracticeActionStyle()).disabled(store.session.index == 0).accessibilityLabel("上一题")
                Spacer()
                Button { store.next() } label: { HStack { Text(store.nextLabel); Image(systemName: "arrow.right").font(.caption.bold()) }.font(.system(size: 21, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 30) }.buttonStyle(PracticeActionStyle(prominent: true))
            }
            Spacer(minLength: 0)
        }
    }

    private var keypad: some View {
        let keys = store.comparison ? [">", "<", "="] : ["1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "0", "delete"]
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
            ForEach(keys, id: \.self) { key in
                Button { store.input(key) } label: {
                    Group {
                        if key == "delete" { Image(systemName: "delete.left") }
                        else if key == "clear" { Image(systemName: "eraser") }
                        else { Text(["clear": "C", ">": "＞", "<": "＜", "=": "＝"][key] ?? key) }
                    }.font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(ink.opacity(0.88))
                        .shadow(color: .white.opacity(0.9), radius: 0, y: 1)
                        .frame(maxWidth: .infinity).frame(height: store.comparison ? 90 : 60)
                }.buttonStyle(GlassKeyStyle(accent: key == "clear" || key == "delete")).accessibilityLabel(["clear": "清空本空", "delete": "删除一位", ">": "大于", "<": "小于", "=": "等于"][key] ?? key)
            }
        }
        // Four numeric rows: 4 × 60pt keys + 3 × 7pt gaps.
        // Comparison keys use the same reserved space so sibling controls never move.
        .frame(height: 261, alignment: .center)
        .groupedGlass()
        .animation(nil, value: store.comparison)
    }

    private var nearbyQuestions: some View {
        let visibleCount = min(5, store.questions.count)
        let start = max(0, min(store.session.index - 2, store.questions.count - visibleCount))
        return HStack(spacing: 12) {
            ForEach(start..<(start + visibleCount), id: \.self) { index in
                let current = store.session.index == index
                Button { store.navigate(index) } label: {
                    Text("\(index + 1)")
                        .font(.system(size: 20, weight: current ? .bold : .medium, design: .rounded))
                        .monospacedDigit()
                        .frame(width: 46, height: 46)
                        .foregroundStyle(current ? .white : purple.opacity(0.8))
                        .background(current ? purple : store.session.isComplete(index) ? mint.opacity(0.18) : .white.opacity(0.45), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.8), lineWidth: 1))
                }.buttonStyle(.plain)
                    .accessibilityLabel("第\(index + 1)题\(current ? "，当前题" : store.session.isComplete(index) ? "，已完成" : "")")
            }
        }.frame(maxWidth: .infinity).padding(.bottom, 8)
    }

    private var resultView: some View {
        let correct = store.session.correctCount(questions: store.questions)
        return VStack(spacing: 20) {
            Image(systemName: correct == store.questions.count ? "star.circle.fill" : "checkmark.circle.fill").font(.system(size: 65)).foregroundStyle(.orange.opacity(0.7))
            Text(correct == store.questions.count ? "全对！" : "完成！").font(.largeTitle.bold()).foregroundStyle(purple)
            HStack(spacing: 60) {
                statistic("本次用时", value: "\(PracticeStore.seconds(store.session.elapsed())) 秒")
                statistic("答对题数", value: "\(correct) / \(store.questions.count)")
                if let best = store.best { statistic("最快", value: "\(PracticeStore.seconds(best.seconds)) 秒") }
            }.padding(20)
            if store.session.isNewRecord { Label("新纪录！", systemImage: "trophy.fill").foregroundStyle(.orange) }
            HStack(spacing: 15) {
                if store.isReview { Button("返回整套") { store.leaveReview() }.buttonStyle(PracticeActionStyle()) }
                Button("再练一次") { store.restart() }.buttonStyle(PracticeActionStyle(prominent: true)).controlSize(.large)
                Button("记录") { store.showingHistory = true }.buttonStyle(PracticeActionStyle()).controlSize(.large)
            }
            if correct < store.questions.count {
                Divider()
                ScrollView {
                    VStack(alignment: .leading, spacing: 13) {
                        Text("错题 · \(store.questions.count - correct)").font(.headline)
                        ForEach(store.questions.indices.filter { !store.session.isCorrect($0, questions: store.questions) }, id: \.self) { i in
                            VStack(alignment: .leading, spacing: 5) {
                                Text("第 \(i + 1) 题 · \(store.questions[i].plainText)")
                                Text("你的答案：\(store.session.answers[i].joined(separator: "，"))    正确答案：\(store.questions[i].answers.joined(separator: "，"))").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }.frame(maxHeight: 160)
            }
        }.padding(35).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    private func statistic(_ label: String, value: String) -> some View {
        VStack(spacing: 7) { Text(value).font(.system(size: 28, weight: .bold, design: .rounded)).monospacedDigit().foregroundStyle(purple); Text(label).font(.caption).foregroundStyle(.secondary) }
    }
    var restartView: some View {
        VStack(spacing: 24) {
            Image(systemName: "arrow.counterclockwise")
                .font(.system(size: 32, weight: .medium))
                .foregroundStyle(purple)
                .frame(width: 78, height: 78)
                .practiceGlass(radius: 25, tint: .indigo.opacity(0.08))
                .accessibilityHidden(true)
            Text("从头再做一次？")
                .font(.system(size: 27, weight: .semibold, design: .rounded))
                .foregroundStyle(ink)
            HStack(spacing: 14) {
                Button { store.confirmingRestart = false } label: {
                    Text("继续做").font(.system(size: 20, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 28)
                }.buttonStyle(PracticeActionStyle()).keyboardShortcut(.cancelAction)
                Button { store.restart() } label: {
                    Text("重新开始").font(.system(size: 20, weight: .semibold)).frame(maxWidth: .infinity).frame(height: 28)
                }.buttonStyle(PracticeActionStyle(prominent: true))
            }
        }
        .padding(32)
        .practiceSheetSize(width: 460, height: 300)
        .background(PracticeBackdrop())
        .preferredColorScheme(.light)
    }

    var historyView: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Text("练习记录").font(.system(size: 26, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button { store.showingHistory = false } label: {
                    Image(systemName: "xmark").font(.system(size: 16, weight: .medium)).frame(width: 20, height: 20)
                }.buttonStyle(PracticeActionStyle()).keyboardShortcut(.cancelAction).accessibilityLabel("关闭练习记录")
            }
            HStack(spacing: 16) {
                Text("用时").frame(maxWidth: .infinity, alignment: .leading)
                Text("错题").frame(width: 105, alignment: .trailing)
                Color.clear.frame(width: 30, height: 1)
            }.font(.system(size: 16, weight: .medium)).foregroundStyle(.secondary).padding(.horizontal, 18)
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    if store.archive.records.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "clock").font(.system(size: 24)).foregroundStyle(purple)
                            Text("还没有记录").font(.system(size: 18)).foregroundStyle(.secondary)
                            Spacer()
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(.white.opacity(0.5), in: RoundedRectangle(cornerRadius: 17))
                    }
                    ForEach(store.archive.records) { record in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .center, spacing: 16) {
                                VStack(alignment: .leading, spacing: 7) {
                                    Text("\(PracticeStore.seconds(record.seconds)) 秒")
                                        .font(.system(size: 25, weight: .semibold, design: .rounded)).monospacedDigit().foregroundStyle(purple)
                                    Text(record.date, format: .dateTime.month().day().hour().minute())
                                        .font(.system(size: 14)).foregroundStyle(.secondary)
                                    if record.isReviewPractice { Text("错题练习").font(.system(size: 14)).foregroundStyle(purple) }
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text("错 \(record.wrongCount) 题")
                                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                                        .foregroundStyle(record.wrongCount > 0 ? Color.orange : purple)
                                    Text("\(record.correct) / \(record.total)").font(.system(size: 14)).foregroundStyle(.secondary)
                                }.monospacedDigit().frame(width: 105, alignment: .trailing)
                                Image(systemName: "trophy.fill").font(.system(size: 21)).foregroundStyle(.orange)
                                    .frame(width: 30).opacity(record.id == store.best?.id ? 1 : 0)
                                    .accessibilityLabel(record.id == store.best?.id ? "最快纪录" : "")
                            }
                            if record.canReview {
                                HStack {
                                    Spacer()
                                    Button { store.review(record) } label: {
                                        Label("练错题", systemImage: "arrow.right").font(.system(size: 18, weight: .semibold)).frame(minHeight: 26)
                                    }.buttonStyle(PracticeActionStyle(prominent: true))
                                }
                            } else if record.wrongCount > 0 {
                                Text("旧记录未保存具体题目").font(.system(size: 14)).foregroundStyle(.secondary)
                            }
                        }
                        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 17))
                        .overlay(RoundedRectangle(cornerRadius: 17).stroke(.white.opacity(0.7), lineWidth: 1))
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).padding(.bottom, 4)
            }
        }
        .padding(28)
        .practiceSheetSize(width: 620, height: 480)
        .foregroundStyle(ink)
        .background(PracticeBackdrop())
        .preferredColorScheme(.light)
    }
}
