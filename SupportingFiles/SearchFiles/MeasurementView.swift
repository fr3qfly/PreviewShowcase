//
//  ContentView.swift
//  SmartLoadCell
//
//  Created by Balázs Szamódy on 5/9/2022.
//

import SwiftUI
import SwiftUICharts

struct MeasurementView: View {
	@StateObject var viewModel: MeasurementViewModel

	@StateObject var chartLayoutManager = SLCChartLayoutManager()

	@State
	private var size: CGSize = .zero
	@State
	private var isSelectingUnit = false
	@State
	private var showAlert = false
	@State
	private var showComment = false

	@ViewBuilder
	private var lineChart: some View {
        if viewModel.showChart, viewModel.chartError == nil {
			SLCChartView(viewModel: viewModel.chartViewModel)
				.frame(height: 250)
				.transaction { transaction in
					transaction.animation = nil
				}
				.dynamicTypeSize(.medium)
                .overlay(content: {
                    if viewModel.shouldShowChartHint {
                        VStack {
                            Text(viewModel.chartNotificationTitle)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text(viewModel.chartNotificationHint)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                    }
                })
				.onTapGesture {
					viewModel.toggleMeasurement()
				}
				.environmentObject(chartLayoutManager)
        } else if viewModel.chartError != nil {
            Text("There was an error drawing the chart please check device settings")
                .font(.callout)
                .padding(16)
        } else {
			Text("Please connect a SmartLoadCell")
				.font(.callout)
				.padding(16)
		}
		
	}

	var body: some View {
		List {
			Section {
				lineChart
			}
			Section {
				HStack {
					Text(viewModel.deviceStatusLabel)
					Spacer()
					TestModePicker(selectedMode: $viewModel.selectedTestMode)
				}
			}

			Section {
				if viewModel.isDualChannel {
					DualValueRow(
						title: Strings.measurementUnitLabel,
						UnitPicker(selectedUnit: $viewModel.channel1Unit, units: viewModel.channel1SelectableUnits, backgroundColor: .blue.opacity(0.25)),
						UnitPicker(selectedUnit: $viewModel.channel2Unit, units: viewModel.channel2SelectableUnits, backgroundColor: .green.opacity(0.25)))
					DualValueRow(
						title: Strings.measurementCurrentLabel,
						value1: viewModel.channel1MeasuredValue,
						value2: viewModel.channel2MeasuredValue,
						font: .title2,
						weight: .semibold)
					DualValueRow(
						title: Strings.measurementMaxLabel,
						value1: viewModel.channel1Max,
						value2: viewModel.channel2Max,
						font: .title2,
						weight: .semibold,
                        backgroundColors: viewModel.maxRangeCheckColors)
				} else {
					ItemRow(title: Strings.measurementUnitLabel, content: UnitPicker(selectedUnit: $viewModel.channel1Unit, units: viewModel.channel1SelectableUnits))
					ItemRow(
						title: Strings.measurementCurrentLabel,
						value: viewModel.channel1MeasuredValue,
						font: .title,
						weight: .semibold)
					ItemRow(
						title: Strings.measurementMaxLabel,
						value: viewModel.channel1Max,
						font: .title,
						weight: .semibold,
                        backgroundColor: viewModel.maxRangeCheckColors.0)
				}
			}
			Section {
				HStack {
					Button {
						viewModel.didTapClear()
					} label: {
						Text(Strings.clear)
					}
					.buttonStyle(.bordered)
					Spacer()
					Button {
						viewModel.didTapTare()
					} label: {
						Text(Strings.tare)
					}
					.buttonStyle(.bordered)
					Spacer()
					Button {
						showComment = true
					} label: {
						Text(Strings.comment)
					}
					.buttonStyle(.bordered)
					.disabled(viewModel.isCommentDisabled)
					Spacer()
					Button {
						viewModel.didTapSave()
					} label: {
						Text(Strings.save) // TODO: Handle AutoSave
					}
					.buttonStyle(.bordered)
				}
				.listRowBackground(Color.clear)
			}
		}
        .listStyle(.insetGrouped)
		.toolbar {
			ToolbarItem(placement: .navigationBarTrailing) {
				if viewModel.hasConnectedDevice {
					Button {
						viewModel.didTapTurnOff()
					} label: {
						Image(systemName: "power.circle.fill")
							.font(.callout)
					}
					.buttonStyle(.plain)
					.foregroundColor(.blue)
				}
			}

			ToolbarItem(placement: .navigationBarTrailing) {
				if viewModel.hasConnectedDevice {
					Menu {
						Button {

						} label: {
							HStack(alignment: .center) {
								if let percentage = viewModel.batteryPercentage {
									Text("\(percentage)%")
								}
								Image(systemName: viewModel.batteryIcon)
									.font(.system(size: 40))
							}
						}
						.buttonStyle(.plain)
						.disabled(true)
					} label: {
						Image(systemName: viewModel.batteryIcon)
							.font(.callout)
					}
				}
			}

			ToolbarItem(placement: .navigationBarTrailing) {
				if viewModel.hasConnectedDevice {
					Button {
						viewModel.didTapReconnect()
					} label: {
						Image(systemName: "antenna.radiowaves.left.and.right")
							.font(.callout)
							.foregroundColor(.green)
					}
					.buttonStyle(.plain)

				} else if viewModel.isTryingToConnect {
					ProgressView()
				} else {
					Button {
						viewModel.didTapReconnect()
					} label: {
						Image(systemName: "antenna.radiowaves.left.and.right.slash")
							.font(.callout)
							.foregroundColor(.red)
					}
					.buttonStyle(.plain)
				}

			}
		}
		.navigationTitle(Strings.measurementScreenTitle)
		.showConnectScreen($viewModel.showConnectScreen) // Have to refactor if different kinds of screens have to be presented
		.alert(viewModel.alertTitle, isPresented: $showAlert) {
			if let alertAction = viewModel.alertAction {
				Button(role: .destructive) {
					alertAction()
				} label: {
					Text(Strings.ok)
				}
			}
		}
		.sheet(isPresented: $showComment, content: {
			if #available(iOS 16, *) {
				CommentView(viewModel: viewModel.commentViewModel())
					.presentationDetents([.fraction(0.3)])
			} else {
				CommentView(viewModel: viewModel.commentViewModel())
			}
		})
		.onChange(of: viewModel.alert) { alert in
			showAlert = alert != nil
		}
		.onChange(of: showAlert) { showAlert in
			guard !showAlert else {
				return
			}
			viewModel.alert = nil
		}
		.onChange(of: viewModel.channel1Unit) { _ in
			chartLayoutManager.resetChannel1LabelWidths()
		}
		.onChange(of: viewModel.channel2Unit) { _ in
			chartLayoutManager.resetChannel2LabelWidths()
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		MeasurementView(viewModel: MeasurementViewModel())
	}
}

struct ItemRow<Content>: View where Content: View {
	var title: String
	var content: () -> Content

	var body: some View {
		HStack {
			Text(title)
			Spacer()
			content()
		}
	}

	init(title: String, content: @autoclosure @escaping () -> Content) {
		self.title = "\(title):"
		self.content = content
	}

    init(title: String, value: String, font: Font = .body, weight: Font.Weight = .regular, backgroundColor: Color? = nil) where Content == TextValueView {
		self.init(title: title, content: TextValueView(value, font: font, weight: weight, backgroundColor: backgroundColor))
	}
}

struct TestModePicker: View {
	@Binding var selectedMode: TestMode

	var body: some View {
		Picker("", selection: $selectedMode) {
			ForEach(TestMode.allCases) {
				Text($0.name)
					.tag($0)
			}
		}
	}
}

struct SamplingRatePicker: View {
	@Binding var selectedSamplingRate: SamplingRate
	var samplingRates: [SamplingRate] = SamplingRate.allCases

	var body: some View {
		Picker("", selection: $selectedSamplingRate) {
			ForEach(samplingRates) {
				Text($0.displayValue)
					.tag($0)
			}
		}
	}
}

struct UnitPicker: View {
	@Binding var selectedUnit: Unit
	var units: [Unit] = Unit.allCases
	var backgroundColor: Color? = nil

	var body: some View {
		Picker("", selection: $selectedUnit) {
			ForEach(units) {
				Text($0.name)
					.tag($0)
			}
		}
		.padding(.trailing, 16)
		.background {
			Capsule()
				.foregroundColor(backgroundColor ?? .clear)
		}
	}
}


