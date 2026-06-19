import WidgetKit
import SwiftUI
import SwiftData

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), todayTotal: 42.50)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), todayTotal: getTodayTotal())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, todayTotal: getTodayTotal())
        
        // Atualiza o widget a cada 15 minutos
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    // Método auxiliar para buscar despesas do dia diretamente do SwiftData compartilhado
    private func getTodayTotal() -> Double {
        let sharedDirectory = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.leomartinez.ExpenseAssistant")
        let databaseURL = sharedDirectory?.appendingPathComponent("default.store")
        
        let config: ModelConfiguration
        if let databaseURL = databaseURL {
            config = ModelConfiguration(url: databaseURL)
        } else {
            config = ModelConfiguration()
        }
        
        do {
            let container = try ModelContainer(for: Expense.self, configurations: config)
            let context = ModelContext(container)
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            let endOfToday = calendar.date(byAdding: .day, value: 1, to: startOfToday)!
            
            let descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    expense.date >= startOfToday && expense.date < endOfToday
                }
            )
            let expenses = try context.fetch(descriptor)
            return expenses.reduce(0.0) { $0 + $1.totalAmount }
        } catch {
            return 0.0
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let todayTotal: Double
}

struct ExpenseWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(.blue)
                Text("ExpenseAssistant")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            Text("Gastos de Hoje")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(String(format: "R$ %.2f", entry.todayTotal))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
            
            Spacer()
            
            // Barra de progresso da meta diária (limite de R$ 150)
            VStack(alignment: .leading, spacing: 4) {
                let limit = 150.0
                let progress = min(entry.todayTotal / limit, 1.0)
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color(.systemGray6))
                            .frame(height: 6)
                        Capsule()
                            .fill(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress, height: 6)
                    }
                }
                .frame(height: 6)
                
                Text(String(format: "%.0f%% da meta diária (R$ 150)", progress * 100))
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .containerBackground(Color(.systemBackground), for: .widget)
    }
}

struct ExpenseWidget: Widget {
    let kind: String = "ExpenseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            ExpenseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("ExpenseAssistant Widget")
        .description("Acompanhe o total de gastos do dia atual.")
        .supportedFamilies([.systemSmall])
    }
}

struct ExpenseWidget_Previews: PreviewProvider {
    static var previews: some View {
        ExpenseWidgetEntryView(entry: SimpleEntry(date: Date(), todayTotal: 78.90))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
