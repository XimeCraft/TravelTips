import Foundation
import SwiftData

// MARK: - First-launch seed

func seedIfNeeded(context: ModelContext) {
    let count = (try? context.fetchCount(FetchDescriptor<Trip>())) ?? 0
    guard count == 0 else { return }
    let trip = makeEgyptTrip()
    context.insert(trip)
    try? context.save()
}

// MARK: - Packing list seed (global, shared across trips)

func seedPackingIfNeeded(context: ModelContext) {
    let tagCount = (try? context.fetchCount(FetchDescriptor<PackingTag>())) ?? 0
    let itemCount = (try? context.fetchCount(FetchDescriptor<PackingItem>())) ?? 0
    guard tagCount == 0 && itemCount == 0 else { return }

    let tags = ["衣物", "洗漱", "电子", "娱乐", "随身", "证件", "其他"]
    for (i, name) in tags.enumerated() {
        context.insert(PackingTag(name: name, sortOrder: i))
    }

    // (name, tag) — tags are a best-guess starting point; easy to re-tag in-app.
    let items: [(String, String)] = [
        ("短袖", "衣物"), ("卫衣", "衣物"), ("防晒衣", "衣物"),
        ("外套 - JORDAN", "衣物"), ("外套 - 绿", "衣物"), ("外套 - 冲锋衣", "衣物"),
        ("长裤", "衣物"), ("短裤", "衣物"), ("睡衣短裤", "衣物"),
        ("内衣", "衣物"), ("内裤", "衣物"), ("袜子", "衣物"),
        ("运动鞋", "衣物"), ("拖鞋", "衣物"), ("棒球帽", "衣物"), ("户外帽", "衣物"),
        ("一次性内裤", "衣物"), ("一次性袜子", "衣物"),
        ("游泳衣", "衣物"), ("水母衣", "衣物"), ("水母裤", "衣物"), ("沙滩裤", "衣物"),
        ("浴巾", "洗漱"), ("洗漱包", "洗漱"), ("一次性浴巾", "洗漱"),
        ("补水口罩", "洗漱"), ("口罩", "洗漱"), ("酒精湿巾", "洗漱"),
        ("马桶垫", "洗漱"), ("消毒啫喱", "洗漱"), ("防晒霜", "洗漱"),
        ("手表充电", "电子"), ("type-c", "电子"), ("接线头", "电子"),
        ("充电宝", "电子"), ("转接头", "电子"), ("ipad", "电子"), ("mac", "电子"),
        ("手机", "电子"), ("手表", "电子"), ("耳机", "电子"), ("手机防水袋", "电子"),
        ("小龙", "娱乐"), ("书", "娱乐"), ("游泳镜", "娱乐"), ("游泳包", "娱乐"),
        ("墨镜", "随身"), ("雨伞", "随身"), ("垃圾袋", "随身"), ("笔", "随身"),
        ("水杯", "随身"), ("枕头", "随身"), ("行李箱", "随身"), ("背包", "随身"), ("小挎包", "随身"),
        ("护照", "证件"), ("借记卡 - DBS", "证件"), ("信用卡 - 招行", "证件"), ("借记卡 - 招行", "证件"),
        ("医药包", "其他"), ("液体创可贴", "其他"), ("布洛芬", "其他"), ("卫生巾", "其他"),
    ]
    for (i, pair) in items.enumerated() {
        context.insert(PackingItem(name: pair.0, tag: pair.1, sortOrder: i))
    }
    try? context.save()
}

// MARK: - Egypt Trip 2026-03-12 → 03-23

private func makeEgyptTrip() -> Trip {
    let trip = Trip(
        name: "Egypt",
        emoji: "🇪🇬",
        startDate: date("2026-03-12"),
        endDate: date("2026-03-23"),
        colorHex: "076C44"
    )

    // ── Info Items ────────────────────────────────────────────────────────────
    trip.infoItems = [
        InfoItem(title: "Visa on Arrival",
                 details: "USD $25, single entry. Payable at airport counter before immigration. Bring passport photo.",
                 sortOrder: 0),
        InfoItem(title: "SIM Card",
                 details: "Buy Vodafone or Orange SIM at Cairo Airport arrivals hall. ~200 EGP for 10GB/15 days.",
                 sortOrder: 1),
        InfoItem(title: "Currency Exchange",
                 details: "Egyptian Pound (EGP). ~1 USD ≈ 50 EGP. Exchange at airport or ATM. Carry small bills for tips.",
                 sortOrder: 2),
        InfoItem(title: "Emergency Contacts",
                 details: "Police: 122 | Ambulance: 123 | Chinese Embassy: +20-2-27361219",
                 sortOrder: 3),
        InfoItem(title: "Travel Insurance",
                 details: "Keep policy number & emergency hotline screenshot offline.",
                 sortOrder: 4),
    ]

    // ── Day 1 — March 12 — Cairo ──────────────────────────────────────────────
    let day1 = TripDay(date: date("2026-03-12"), city: "Cairo",
                       summary: "Arrive Cairo + Egyptian Museum", sortOrder: 0)
    let t1 = TransportInfo(type: .flight, detail: "3U3863",
                           from: "Chengdu TFU T1", to: "Cairo CAI T2",
                           departureTime: "01:40", arrivalTime: "06:30")
    day1.transports = [t1]
    let a1 = Accommodation(name: "Ramses Hilton",
                           address: "1115 Corniche El Nil, Cairo", isCheckIn: true)
    day1.accommodation = a1
    let p1 = Destination(name: "The Egyptian Museum in Cairo", type: .attraction,
                         time: "14:00-17:00", address: "Tahrir Square, Cairo",
                         ticketPrice: "450 EGP", notes: "Old museum, still worth visiting", sortOrder: 0)
    day1.destinations = [p1]
    day1.timelineItems = [
        TimelineItem(time: "06:30", title: "Arrive Cairo Airport T2",
                     note: "Visa → SIM card → Currency exchange",
                     type: .flight, linkedId: t1.id, sortOrder: 0),
        TimelineItem(time: "08:30", title: "Transfer to Ramses Hilton",
                     note: "Taxi/Uber ~250 EGP, 30 min",
                     type: .drive, sortOrder: 1),
        TimelineItem(time: "09:00", title: "Check-in Ramses Hilton",
                     note: "Check-in, freshen up",
                     type: .hotel, linkedId: a1.id, sortOrder: 2),
        TimelineItem(time: "14:00", title: "The Egyptian Museum",
                     note: "Tahrir Square · 450 EGP · 2-3 hrs",
                     type: .attraction, linkedId: p1.id, sortOrder: 3),
        TimelineItem(time: "19:00", title: "Dinner",
                     note: "Explore nearby restaurants",
                     type: .restaurant, sortOrder: 4),
    ]
    trip.days.append(day1)

    // ── Day 2 — March 13 — Cairo → Luxor ─────────────────────────────────────
    let day2 = TripDay(date: date("2026-03-13"), city: "Cairo → Luxor",
                       summary: "Giza Pyramids + Grand Egyptian Museum → Fly to Luxor", sortOrder: 1)
    let t2 = TransportInfo(type: .flight, detail: "Flight",
                           from: "Cairo", to: "Luxor",
                           departureTime: "21:00", arrivalTime: "22:40")
    day2.transports = [t2]
    let a2 = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                           address: "Luxor City, Luxor", isCheckIn: true)
    day2.accommodation = a2
    let p2 = Destination(name: "GIZA Pyramids", type: .attraction,
                         time: "08:00-12:00", address: "Al Haram, Giza",
                         ticketPrice: "540 EGP", notes: "Go early to avoid heat", sortOrder: 0)
    let p3 = Destination(name: "Grand Egyptian Museum", type: .attraction,
                         time: "13:00-17:00", address: "Grand Egyptian Museum, Giza",
                         ticketPrice: "600 EGP", notes: "New museum, allow 3-4 hours", sortOrder: 1)
    day2.destinations = [p2, p3]
    day2.timelineItems = [
        TimelineItem(time: "07:00", title: "Head to Giza",
                     note: "~30 min from hotel",
                     type: .drive, sortOrder: 0),
        TimelineItem(time: "08:00", title: "GIZA Pyramids",
                     note: "540 EGP · Camel rides optional",
                     type: .attraction, linkedId: p2.id, sortOrder: 1),
        TimelineItem(time: "12:00", title: "Lunch near Giza",
                     type: .restaurant, sortOrder: 2),
        TimelineItem(time: "13:00", title: "Grand Egyptian Museum",
                     note: "600 EGP · Brand new",
                     type: .attraction, linkedId: p3.id, sortOrder: 3),
        TimelineItem(time: "17:00", title: "Return & pack",
                     note: "Head to airport",
                     type: .other, sortOrder: 4),
        TimelineItem(time: "21:00", title: "Flight to Luxor",
                     note: "Arrive 22:40",
                     type: .flight, linkedId: t2.id, sortOrder: 5),
    ]
    trip.days.append(day2)

    // ── Day 3 — March 14 — Luxor ──────────────────────────────────────────────
    let day3 = TripDay(date: date("2026-03-14"), city: "Luxor",
                       summary: "Karnak Temple + Ferry Tour", sortOrder: 2)
    day3.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    let p4 = Destination(name: "Karnak Temple", type: .attraction,
                         time: "08:00-11:00", address: "Karnak, Luxor",
                         ticketPrice: "300 EGP", notes: "Largest ancient religious site", sortOrder: 0)
    let p5 = Destination(name: "Nile Ferry Tour", type: .activity,
                         time: "15:00-17:00", address: "Nile River, Luxor",
                         ticketPrice: "~100 EGP", notes: "Sunset felucca ride", sortOrder: 1)
    day3.destinations = [p4, p5]
    day3.timelineItems = [
        TimelineItem(time: "08:00", title: "Karnak Temple",
                     note: "300 EGP · Huge complex",
                     type: .attraction, linkedId: p4.id, sortOrder: 0),
        TimelineItem(time: "12:00", title: "Lunch",
                     type: .restaurant, sortOrder: 1),
        TimelineItem(time: "15:00", title: "Nile Ferry Tour",
                     note: "Felucca · Sunset views",
                     type: .activity, linkedId: p5.id, sortOrder: 2),
    ]
    trip.days.append(day3)

    // ── Day 4 — March 15 — Luxor ──────────────────────────────────────────────
    let day4 = TripDay(date: date("2026-03-15"), city: "Luxor",
                       summary: "Hot Air Balloon + Luxor Temple + Avenue of Sphinxes", sortOrder: 3)
    day4.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    let p6 = Destination(name: "🎈 Hot Air Balloon", type: .activity,
                         time: "05:00-07:00", address: "West Bank, Luxor",
                         ticketPrice: "~$80-150 USD", notes: "Sunrise flight, book ahead", sortOrder: 0)
    let p7 = Destination(name: "Luxor Temple", type: .attraction,
                         time: "10:00-12:00", address: "Luxor City Center",
                         ticketPrice: "260 EGP", notes: "Beautiful at sunset too", sortOrder: 1)
    let p8 = Destination(name: "Avenue of Sphinxes", type: .attraction,
                         time: "12:00-13:00", address: "Connecting Karnak & Luxor Temple",
                         ticketPrice: "Free", notes: "2.7km ancient road", sortOrder: 2)
    day4.destinations = [p6, p7, p8]
    day4.timelineItems = [
        TimelineItem(time: "04:30", title: "Hot Air Balloon pickup",
                     note: "Sunrise over West Bank",
                     type: .activity, linkedId: p6.id, sortOrder: 0),
        TimelineItem(time: "07:00", title: "Return & Breakfast",
                     type: .other, sortOrder: 1),
        TimelineItem(time: "10:00", title: "Luxor Temple",
                     note: "260 EGP",
                     type: .attraction, linkedId: p7.id, sortOrder: 2),
        TimelineItem(time: "12:00", title: "Avenue of Sphinxes",
                     note: "Free · Walk 2.7km",
                     type: .attraction, linkedId: p8.id, sortOrder: 3),
    ]
    trip.days.append(day4)

    // ── Day 5 — March 16 — Luxor ──────────────────────────────────────────────
    let day5 = TripDay(date: date("2026-03-16"), city: "Luxor",
                       summary: "Valley of the Kings + Hatshepsut + Colossi of Memnon", sortOrder: 4)
    day5.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    let p9 = Destination(name: "Valley of the Kings", type: .attraction,
                         time: "07:00-10:00", address: "West Bank, Luxor",
                         ticketPrice: "600 EGP (3 tombs)", notes: "No photos inside tombs", sortOrder: 0)
    let p10 = Destination(name: "Temple of Hatshepsut", type: .attraction,
                          time: "10:30-12:00", address: "West Bank, Luxor",
                          ticketPrice: "240 EGP", notes: "Iconic terraced temple", sortOrder: 1)
    let p11 = Destination(name: "Colossi of Memnon", type: .attraction,
                          time: "12:30-13:00", address: "West Bank, Luxor",
                          ticketPrice: "Free", notes: "Quick photo stop", sortOrder: 2)
    day5.destinations = [p9, p10, p11]
    day5.timelineItems = [
        TimelineItem(time: "07:00", title: "Valley of the Kings",
                     note: "600 EGP · Go early!",
                     type: .attraction, linkedId: p9.id, sortOrder: 0),
        TimelineItem(time: "10:30", title: "Temple of Hatshepsut",
                     note: "240 EGP",
                     type: .attraction, linkedId: p10.id, sortOrder: 1),
        TimelineItem(time: "12:30", title: "Colossi of Memnon",
                     note: "Free",
                     type: .attraction, linkedId: p11.id, sortOrder: 2),
        TimelineItem(time: "13:30", title: "Lunch & Rest",
                     note: "Last full day in Luxor",
                     type: .restaurant, sortOrder: 3),
    ]
    trip.days.append(day5)

    // ── Day 6 — March 17 — Luxor → Marsa Alam ───────────────────────────────
    let day6 = TripDay(date: date("2026-03-17"), city: "Luxor → Marsa Alam",
                       summary: "Drive to Marsa Alam", sortOrder: 5)
    let t3 = TransportInfo(type: .drive, detail: "Drive",
                           from: "Luxor", to: "Marsa Alam",
                           departureTime: "", arrivalTime: "")
    day6.transports = [t3]
    let a6 = Accommodation(name: "JAZ Elite Maraya",
                           address: "Marsa Alam, Red Sea", isCheckIn: true)
    day6.accommodation = a6
    day6.timelineItems = [
        TimelineItem(time: "09:00", title: "Check out Sonesta",
                     note: "Pack & check out",
                     type: .hotel, sortOrder: 0),
        TimelineItem(time: "09:30", title: "Drive to Marsa Alam",
                     note: "~4-5 hours drive",
                     type: .drive, linkedId: t3.id, sortOrder: 1),
        TimelineItem(time: "14:30", title: "Check in JAZ Maraya",
                     note: "Resort time!",
                     type: .hotel, linkedId: a6.id, sortOrder: 2),
    ]
    trip.days.append(day6)

    // ── Days 7-9 — March 18-20 — Marsa Alam ─────────────────────────────────
    for (dateStr, sortOrder) in [("2026-03-18", 6), ("2026-03-19", 7), ("2026-03-20", 8)] {
        let day = TripDay(date: date(dateStr), city: "Marsa Alam",
                          summary: "Beach & Resort Day", sortOrder: sortOrder)
        day.accommodation = Accommodation(name: "JAZ Elite Maraya",
                                          address: "Marsa Alam, Red Sea")
        day.timelineItems = [
            TimelineItem(time: "All Day", title: "Resort & Beach",
                         note: "Relax, snorkel, dive",
                         type: .activity, sortOrder: 0),
        ]
        trip.days.append(day)
    }

    // ── Day 10 — March 21 — Marsa Alam → Cairo ──────────────────────────────
    let day10 = TripDay(date: date("2026-03-21"), city: "Marsa Alam → Cairo",
                        summary: "Fly back to Cairo", sortOrder: 9)
    let t4 = TransportInfo(type: .flight, detail: "Flight",
                           from: "Marsa Alam", to: "Cairo",
                           departureTime: "18:10", arrivalTime: "19:10")
    day10.transports = [t4]
    let a10 = Accommodation(name: "Novotel Cairo Airport Hotel",
                            address: "Cairo Airport, Cairo", isCheckIn: true)
    day10.accommodation = a10
    day10.timelineItems = [
        TimelineItem(time: "All Day", title: "Resort morning",
                     note: "Last morning at resort",
                     type: .activity, sortOrder: 0),
        TimelineItem(time: "16:00", title: "Head to airport",
                     type: .drive, sortOrder: 1),
        TimelineItem(time: "18:10", title: "Flight to Cairo",
                     note: "Arrive 19:10",
                     type: .flight, linkedId: t4.id, sortOrder: 2),
        TimelineItem(time: "20:00", title: "Check in Novotel",
                     note: "Rest before departure",
                     type: .hotel, linkedId: a10.id, sortOrder: 3),
    ]
    trip.days.append(day10)

    // ── Day 11 — March 22 — Cairo → Chengdu ─────────────────────────────────
    let day11 = TripDay(date: date("2026-03-22"), city: "Cairo → Chengdu",
                        summary: "Fly home ✈️", sortOrder: 10)
    let t5 = TransportInfo(type: .flight, detail: "3U3864",
                           from: "Cairo CAI T2", to: "Chengdu TFU T1",
                           departureTime: "14:30", arrivalTime: "05:45+1")
    day11.transports = [t5]
    day11.timelineItems = [
        TimelineItem(time: "12:00", title: "Head to airport",
                     note: "CAI Terminal 2",
                     type: .drive, sortOrder: 0),
        TimelineItem(time: "14:30", title: "Flight 3U3864 to Chengdu",
                     note: "Arrive Mar 23 05:45 TFU T1",
                     type: .flight, linkedId: t5.id, sortOrder: 1),
    ]
    trip.days.append(day11)

    return trip
}

// MARK: - Date helper

private func date(_ string: String) -> Date {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd"
    f.timeZone = TimeZone(identifier: "UTC")
    return f.date(from: string) ?? Date()
}
