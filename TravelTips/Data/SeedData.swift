import Foundation
import SwiftData

// MARK: - First-launch seed

func seedIfNeeded(context: ModelContext) {
    let descriptor = FetchDescriptor<Trip>()
    let count = (try? context.fetchCount(descriptor)) ?? 0
    guard count == 0 else { return }

    let trip = makeEgyptTrip()
    context.insert(trip)
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
                 details: "USD $25, single entry, payable at airport counter before immigration. Bring passport photo.",
                 sortOrder: 0),
        InfoItem(title: "SIM Card",
                 details: "Buy Vodafone or Orange SIM at Cairo Airport arrivals hall. ~200 EGP for 10GB/15 days.",
                 sortOrder: 1),
        InfoItem(title: "Currency Exchange",
                 details: "Egyptian Pound (EGP). Exchange at airport or ATM. ~1 USD ≈ 50 EGP. Carry small bills for tips.",
                 sortOrder: 2),
        InfoItem(title: "Emergency Contacts",
                 details: "Police: 122 | Ambulance: 123 | Chinese Embassy: +20-2-27361219",
                 sortOrder: 3),
        InfoItem(title: "Travel Insurance",
                 details: "Policy number and emergency hotline. Keep screenshot offline.",
                 sortOrder: 4),
    ]

    // ── Day 1 — March 12 — Cairo ──────────────────────────────────────────────
    let day1 = TripDay(date: date("2026-03-12"), city: "Cairo",
                       summary: "Arrive Cairo + Egyptian Museum", sortOrder: 0)
    day1.transport = TransportInfo(type: .flight, detail: "3U3863",
                                   from: "Chengdu TFU T1", to: "Cairo CAI T2",
                                   departureTime: "01:40", arrivalTime: "06:30")
    day1.accommodation = Accommodation(name: "Ramses Hilton",
                                       address: "1115 Corniche El Nil, Cairo",
                                       isCheckIn: true)
    day1.destinations = [
        Destination(name: "The Egyptian Museum in Cairo", type: .attraction,
                    time: "14:00-17:00", address: "Tahrir Square, Cairo",
                    ticketPrice: "450 EGP", notes: "Old museum, still worth visiting",
                    sortOrder: 0),
    ]
    day1.details = [
        DayDetail(time: "06:30", title: "Arrive Cairo Airport T2",
                  note: "Visa on arrival → SIM card → Currency exchange", sortOrder: 0),
        DayDetail(time: "08:30", title: "Transfer to Ramses Hilton",
                  note: "Taxi/Uber ~250 EGP, 30 min", sortOrder: 1),
        DayDetail(time: "09:00", title: "Check-in & Rest",
                  note: "Hotel check-in, freshen up", sortOrder: 2),
        DayDetail(time: "14:00", title: "The Egyptian Museum",
                  note: "Tahrir Square. 450 EGP entry. Allow 2-3 hrs.", sortOrder: 3),
        DayDetail(time: "19:00", title: "Dinner",
                  note: "Explore nearby restaurants", sortOrder: 4),
    ]
    trip.days.append(day1)

    // ── Day 2 — March 13 — Cairo → Luxor ─────────────────────────────────────
    let day2 = TripDay(date: date("2026-03-13"), city: "Cairo → Luxor",
                       summary: "Giza Pyramids + Grand Egyptian Museum → Fly to Luxor", sortOrder: 1)
    day2.transport = TransportInfo(type: .flight, detail: "Flight",
                                   from: "Cairo", to: "Luxor",
                                   departureTime: "21:00", arrivalTime: "22:40")
    day2.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor", isCheckIn: true)
    day2.destinations = [
        Destination(name: "GIZA Pyramids", type: .attraction,
                    time: "08:00-12:00", address: "Al Haram, Giza",
                    ticketPrice: "540 EGP", notes: "Go early to avoid heat", sortOrder: 0),
        Destination(name: "Grand Egyptian Museum", type: .attraction,
                    time: "13:00-17:00", address: "Grand Egyptian Museum, Giza",
                    ticketPrice: "600 EGP", notes: "New museum, allow 3-4 hours", sortOrder: 1),
    ]
    day2.details = [
        DayDetail(time: "07:00", title: "Head to Giza Pyramids",
                  note: "Arrive early, ~30 min from hotel", sortOrder: 0),
        DayDetail(time: "08:00", title: "GIZA Pyramids",
                  note: "540 EGP. Camel rides optional.", sortOrder: 1),
        DayDetail(time: "12:00", title: "Lunch near Giza", sortOrder: 2),
        DayDetail(time: "13:00", title: "Grand Egyptian Museum",
                  note: "600 EGP. Brand new museum.", sortOrder: 3),
        DayDetail(time: "17:00", title: "Return to hotel & pack",
                  note: "Check out, head to airport", sortOrder: 4),
        DayDetail(time: "21:00", title: "Flight to Luxor",
                  note: "Arrive 22:40. Transfer to Sonesta.", sortOrder: 5),
    ]
    trip.days.append(day2)

    // ── Day 3 — March 14 — Luxor ──────────────────────────────────────────────
    let day3 = TripDay(date: date("2026-03-14"), city: "Luxor",
                       summary: "Karnak Temple + Ferry Tour", sortOrder: 2)
    day3.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    day3.destinations = [
        Destination(name: "Karnak Temple", type: .attraction,
                    time: "08:00-11:00", address: "Karnak, Luxor",
                    ticketPrice: "300 EGP", notes: "Largest ancient religious site", sortOrder: 0),
        Destination(name: "Ferry Tour", type: .activity,
                    time: "15:00-17:00", address: "Nile River, Luxor",
                    ticketPrice: "~100 EGP", notes: "Sunset felucca ride", sortOrder: 1),
    ]
    day3.details = [
        DayDetail(time: "08:00", title: "Karnak Temple",
                  note: "300 EGP. Huge complex, wear comfy shoes.", sortOrder: 0),
        DayDetail(time: "12:00", title: "Lunch", sortOrder: 1),
        DayDetail(time: "15:00", title: "Nile Ferry Tour",
                  note: "Felucca boat, sunset views", sortOrder: 2),
    ]
    trip.days.append(day3)

    // ── Day 4 — March 15 — Luxor ──────────────────────────────────────────────
    let day4 = TripDay(date: date("2026-03-15"), city: "Luxor",
                       summary: "Hot Air Balloon + Luxor Temple + Avenue of Sphinxes", sortOrder: 3)
    day4.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    day4.destinations = [
        Destination(name: "热气球 Hot Air Balloon", type: .activity,
                    time: "05:00-07:00", address: "West Bank, Luxor",
                    ticketPrice: "~$80-150 USD", notes: "Sunrise flight, book ahead", sortOrder: 0),
        Destination(name: "Luxor Temple", type: .attraction,
                    time: "10:00-12:00", address: "Luxor City Center",
                    ticketPrice: "260 EGP", notes: "Beautiful at sunset too", sortOrder: 1),
        Destination(name: "Avenue of Sphinxes", type: .attraction,
                    time: "12:00-13:00", address: "Connecting Karnak & Luxor Temple",
                    ticketPrice: "Free", notes: "2.7km ancient road", sortOrder: 2),
    ]
    day4.details = [
        DayDetail(time: "04:30", title: "Pick-up for Hot Air Balloon",
                  note: "Sunrise ride over West Bank", sortOrder: 0),
        DayDetail(time: "07:00", title: "Return & Breakfast", sortOrder: 1),
        DayDetail(time: "10:00", title: "Luxor Temple", note: "260 EGP", sortOrder: 2),
        DayDetail(time: "12:00", title: "Avenue of Sphinxes",
                  note: "Walk between temples, free", sortOrder: 3),
    ]
    trip.days.append(day4)

    // ── Day 5 — March 16 — Luxor ──────────────────────────────────────────────
    let day5 = TripDay(date: date("2026-03-16"), city: "Luxor",
                       summary: "Valley of the Kings + Hatshepsut + Colossi of Memnon", sortOrder: 4)
    day5.accommodation = Accommodation(name: "Sonesta St. George Hotel - Luxor",
                                       address: "Luxor City, Luxor")
    day5.destinations = [
        Destination(name: "Valley of the Kings", type: .attraction,
                    time: "07:00-10:00", address: "West Bank, Luxor",
                    ticketPrice: "600 EGP (3 tombs)", notes: "No photos inside tombs", sortOrder: 0),
        Destination(name: "Mortuary Temple of Hatshepsut", type: .attraction,
                    time: "10:30-12:00", address: "West Bank, Luxor",
                    ticketPrice: "240 EGP", notes: "Iconic terraced temple", sortOrder: 1),
        Destination(name: "Colossi of Memnon", type: .attraction,
                    time: "12:30-13:00", address: "West Bank, Luxor",
                    ticketPrice: "Free", notes: "Quick photo stop", sortOrder: 2),
    ]
    day5.details = [
        DayDetail(time: "07:00", title: "Valley of the Kings",
                  note: "600 EGP for 3 tombs. Go early!", sortOrder: 0),
        DayDetail(time: "10:30", title: "Mortuary Temple of Hatshepsut",
                  note: "240 EGP. Iconic terraced temple.", sortOrder: 1),
        DayDetail(time: "12:30", title: "Colossi of Memnon",
                  note: "Free, quick stop", sortOrder: 2),
        DayDetail(time: "13:30", title: "Lunch & Rest",
                  note: "Last full day in Luxor", sortOrder: 3),
    ]
    trip.days.append(day5)

    // ── Day 6 — March 17 — Luxor → Marsa Alam ───────────────────────────────
    let day6 = TripDay(date: date("2026-03-17"), city: "Luxor → Marsa Alam",
                       summary: "Drive to Marsa Alam", sortOrder: 5)
    day6.transport = TransportInfo(type: .drive, detail: "Drive",
                                   from: "Luxor", to: "Marsa Alam",
                                   departureTime: "", arrivalTime: "")
    day6.accommodation = Accommodation(name: "JAZ Elite Maraya",
                                       address: "Marsa Alam, Red Sea", isCheckIn: true)
    day6.details = [
        DayDetail(time: "09:00", title: "Check out Sonesta",
                  note: "Pack & check out", sortOrder: 0),
        DayDetail(time: "09:30", title: "Drive to Marsa Alam",
                  note: "~4-5 hours drive", sortOrder: 1),
        DayDetail(time: "14:30", title: "Check in JAZ Elite Maraya",
                  note: "Resort time!", sortOrder: 2),
    ]
    trip.days.append(day6)

    // ── Days 7-9 — March 18-20 — Marsa Alam ─────────────────────────────────
    for (dateStr, sortOrder) in [("2026-03-18", 6), ("2026-03-19", 7), ("2026-03-20", 8)] {
        let day = TripDay(date: date(dateStr), city: "Marsa Alam",
                          summary: "Beach & Resort Day", sortOrder: sortOrder)
        day.accommodation = Accommodation(name: "JAZ Elite Maraya",
                                          address: "Marsa Alam, Red Sea")
        day.details = [
            DayDetail(time: "All Day", title: "Resort & Beach",
                      note: "Relax, snorkel, dive", sortOrder: 0),
        ]
        trip.days.append(day)
    }

    // ── Day 10 — March 21 — Marsa Alam → Cairo ──────────────────────────────
    let day10 = TripDay(date: date("2026-03-21"), city: "Marsa Alam → Cairo",
                        summary: "Fly back to Cairo", sortOrder: 9)
    day10.transport = TransportInfo(type: .flight, detail: "Flight",
                                    from: "Marsa Alam", to: "Cairo",
                                    departureTime: "18:10", arrivalTime: "19:10")
    day10.accommodation = Accommodation(name: "Novotel Cairo Airport Hotel",
                                        address: "Cairo Airport, Cairo", isCheckIn: true)
    day10.details = [
        DayDetail(time: "All Day", title: "Resort morning",
                  note: "Last morning at resort", sortOrder: 0),
        DayDetail(time: "16:00", title: "Head to airport", sortOrder: 1),
        DayDetail(time: "18:10", title: "Flight to Cairo",
                  note: "Arrive 19:10", sortOrder: 2),
        DayDetail(time: "20:00", title: "Check in Novotel Airport",
                  note: "Rest before departure", sortOrder: 3),
    ]
    trip.days.append(day10)

    // ── Day 11 — March 22 — Cairo → Chengdu ─────────────────────────────────
    let day11 = TripDay(date: date("2026-03-22"), city: "Cairo → Chengdu",
                        summary: "Fly home ✈️", sortOrder: 10)
    day11.transport = TransportInfo(type: .flight, detail: "3U3864",
                                    from: "Cairo CAI T2", to: "Chengdu TFU T1",
                                    departureTime: "14:30", arrivalTime: "05:45+1")
    day11.details = [
        DayDetail(time: "12:00", title: "Head to airport",
                  note: "CAI Terminal 2", sortOrder: 0),
        DayDetail(time: "14:30", title: "Flight 3U3864 to Chengdu",
                  note: "Arrive Mar 23 05:45 TFU T1", sortOrder: 1),
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
