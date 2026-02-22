import { useState, useRef } from "react";

// ─── Theme ───────────────────────────────────────────────────────────────────
const THEME = {
  primary: "#076C44",
  primaryLight: "#0A8A58",
  primaryMuted: "#076C4430",
  primaryFaint: "#076C4412",
  primaryGhost: "#076C4408",
  accent: "#0B9B60",
  bg: "#F4F5F2",
  card: "#FFFFFF",
  text: "#1A1A1A",
  textSec: "#888888",
  textTer: "#AAAAAA",
  border: "rgba(0,0,0,0.06)",
};

// ─── Data ────────────────────────────────────────────────────────────────────
const EGYPT_TRIP = {
  id: "egypt-2026",
  name: "Egypt",
  emoji: "🇪🇬",
  startDate: "2026-03-12",
  endDate: "2026-03-23",
  color: THEME.primary,
  info: {
    visa: { title: "Visa on Arrival", details: "USD $25, single entry, payable at airport counter before immigration. Bring passport photo.", done: false },
    sim: { title: "SIM Card", details: "Buy Vodafone or Orange SIM at Cairo Airport arrivals hall. ~200 EGP for 10GB/15 days.", done: false },
    currency: { title: "Currency Exchange", details: "Egyptian Pound (EGP). Exchange at airport or ATM. ~1 USD ≈ 50 EGP. Carry small bills for tips.", done: false },
    emergency: { title: "Emergency Contacts", details: "Police: 122 | Ambulance: 123 | Chinese Embassy: +20-2-27361219", done: false },
    insurance: { title: "Travel Insurance", details: "Policy number and emergency hotline. Keep screenshot offline.", done: false },
  },
  days: [
    {
      date: "2026-03-12", city: "Cairo", summary: "Arrive Cairo + Egyptian Museum",
      transport: { type: "flight", detail: "3U3863", from: "Chengdu TFU T1", to: "Cairo CAI T2", depTime: "01:40", arrTime: "06:30" },
      accommodation: { name: "Ramses Hilton", address: "1115 Corniche El Nil, Cairo", checkIn: true, checkOut: false },
      destinations: [
        { name: "The Egyptian Museum in Cairo", type: "attraction", time: "14:00-17:00", address: "Tahrir Square, Cairo", ticketPrice: "450 EGP", notes: "Old museum, still worth visiting" }
      ],
      details: [
        { id: "1-1", time: "06:30", title: "Arrive Cairo Airport T2", note: "Visa on arrival → SIM card → Currency exchange", done: false },
        { id: "1-2", time: "08:30", title: "Transfer to Ramses Hilton", note: "Taxi/Uber ~250 EGP, 30min", done: false },
        { id: "1-3", time: "09:00", title: "Check-in & Rest", note: "Hotel check-in, freshen up", done: false },
        { id: "1-4", time: "14:00", title: "The Egyptian Museum", note: "Tahrir Square. 450 EGP entry. Allow 2-3 hrs.", done: false },
        { id: "1-5", time: "19:00", title: "Dinner", note: "Explore nearby restaurants", done: false },
      ]
    },
    {
      date: "2026-03-13", city: "Cairo → Luxor", summary: "Giza Pyramids + Grand Egyptian Museum → Fly to Luxor",
      transport: { type: "flight", detail: "Flight", from: "Cairo", to: "Luxor", depTime: "21:00", arrTime: "22:40" },
      accommodation: { name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: true, checkOut: false },
      destinations: [
        { name: "GIZA Pyramids", type: "attraction", time: "08:00-12:00", address: "Al Haram, Giza", ticketPrice: "540 EGP", notes: "Go early to avoid heat" },
        { name: "Grand Egyptian Museum", type: "attraction", time: "13:00-17:00", address: "Grand Egyptian Museum, Giza", ticketPrice: "600 EGP", notes: "New museum, allow 3-4 hours" }
      ],
      details: [
        { id: "2-1", time: "07:00", title: "Head to Giza Pyramids", note: "Arrive early, ~30min from hotel", done: false },
        { id: "2-2", time: "08:00", title: "GIZA Pyramids", note: "540 EGP. Camel rides optional.", done: false },
        { id: "2-3", time: "12:00", title: "Lunch near Giza", note: "", done: false },
        { id: "2-4", time: "13:00", title: "Grand Egyptian Museum", note: "600 EGP. Brand new museum.", done: false },
        { id: "2-5", time: "17:00", title: "Return to hotel & pack", note: "Check out, head to airport", done: false },
        { id: "2-6", time: "21:00", title: "Flight to Luxor", note: "Arrive 22:40. Transfer to Sonesta.", done: false },
      ]
    },
    {
      date: "2026-03-14", city: "Luxor", summary: "Karnak Temple + Ferry Tour",
      transport: null,
      accommodation: { name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false, checkOut: false },
      destinations: [
        { name: "Karnak Temple", type: "attraction", time: "08:00-11:00", address: "Karnak, Luxor", ticketPrice: "300 EGP", notes: "Largest ancient religious site" },
        { name: "Ferry Tour", type: "activity", time: "15:00-17:00", address: "Nile River, Luxor", ticketPrice: "~100 EGP", notes: "Sunset felucca ride" }
      ],
      details: [
        { id: "3-1", time: "08:00", title: "Karnak Temple", note: "300 EGP. Huge complex, wear comfy shoes.", done: false },
        { id: "3-2", time: "12:00", title: "Lunch", note: "", done: false },
        { id: "3-3", time: "15:00", title: "Nile Ferry Tour", note: "Felucca boat, sunset views", done: false },
      ]
    },
    {
      date: "2026-03-15", city: "Luxor", summary: "Hot Air Balloon + Luxor Temple + Avenue of Sphinxes",
      transport: null,
      accommodation: { name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false, checkOut: false },
      destinations: [
        { name: "热气球 Hot Air Balloon", type: "activity", time: "05:00-07:00", address: "West Bank, Luxor", ticketPrice: "~$80-150 USD", notes: "Sunrise flight, book ahead" },
        { name: "Luxor Temple", type: "attraction", time: "10:00-12:00", address: "Luxor City Center", ticketPrice: "260 EGP", notes: "Beautiful at sunset too" },
        { name: "Avenue of Sphinxes", type: "attraction", time: "12:00-13:00", address: "Connecting Karnak & Luxor Temple", ticketPrice: "Free", notes: "2.7km ancient road" }
      ],
      details: [
        { id: "4-1", time: "04:30", title: "Pick-up for Hot Air Balloon", note: "Sunrise ride over West Bank", done: false },
        { id: "4-2", time: "07:00", title: "Return & Breakfast", note: "", done: false },
        { id: "4-3", time: "10:00", title: "Luxor Temple", note: "260 EGP", done: false },
        { id: "4-4", time: "12:00", title: "Avenue of Sphinxes", note: "Walk between temples, free", done: false },
      ]
    },
    {
      date: "2026-03-16", city: "Luxor", summary: "Valley of the Kings + Hatshepsut + Colossi of Memnon",
      transport: null,
      accommodation: { name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false, checkOut: false },
      destinations: [
        { name: "Valley of the Kings", type: "attraction", time: "07:00-10:00", address: "West Bank, Luxor", ticketPrice: "600 EGP (3 tombs)", notes: "No photos inside tombs" },
        { name: "Mortuary Temple of Hatshepsut", type: "attraction", time: "10:30-12:00", address: "West Bank, Luxor", ticketPrice: "240 EGP", notes: "Iconic terraced temple" },
        { name: "Colossi of Memnon", type: "attraction", time: "12:30-13:00", address: "West Bank, Luxor", ticketPrice: "Free", notes: "Quick photo stop" }
      ],
      details: [
        { id: "5-1", time: "07:00", title: "Valley of the Kings", note: "600 EGP for 3 tombs. Go early!", done: false },
        { id: "5-2", time: "10:30", title: "Mortuary Temple of Hatshepsut", note: "240 EGP. Iconic terraced temple.", done: false },
        { id: "5-3", time: "12:30", title: "Colossi of Memnon", note: "Free, quick stop", done: false },
        { id: "5-4", time: "13:30", title: "Lunch & Rest", note: "Last full day in Luxor", done: false },
      ]
    },
    {
      date: "2026-03-17", city: "Luxor → Marsa Alam", summary: "Drive to Marsa Alam",
      transport: { type: "drive", detail: "Drive", from: "Luxor", to: "Marsa Alam", depTime: "", arrTime: "" },
      accommodation: { name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: true, checkOut: false },
      destinations: [],
      details: [
        { id: "6-1", time: "09:00", title: "Check out Sonesta", note: "Pack & check out", done: false },
        { id: "6-2", time: "09:30", title: "Drive to Marsa Alam", note: "~4-5 hours drive", done: false },
        { id: "6-3", time: "14:30", title: "Check in JAZ Elite Maraya", note: "Resort time!", done: false },
      ]
    },
    {
      date: "2026-03-18", city: "Marsa Alam", summary: "Beach & Resort Day",
      transport: null,
      accommodation: { name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false, checkOut: false },
      destinations: [],
      details: [{ id: "7-1", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", done: false }]
    },
    {
      date: "2026-03-19", city: "Marsa Alam", summary: "Beach & Resort Day",
      transport: null,
      accommodation: { name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false, checkOut: false },
      destinations: [],
      details: [{ id: "8-1", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", done: false }]
    },
    {
      date: "2026-03-20", city: "Marsa Alam", summary: "Beach & Resort Day",
      transport: null,
      accommodation: { name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false, checkOut: false },
      destinations: [],
      details: [{ id: "9-1", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", done: false }]
    },
    {
      date: "2026-03-21", city: "Marsa Alam → Cairo", summary: "Fly back to Cairo",
      transport: { type: "flight", detail: "Flight", from: "Marsa Alam", to: "Cairo", depTime: "18:10", arrTime: "19:10" },
      accommodation: { name: "Novotel Cairo Airport Hotel", address: "Cairo Airport, Cairo", checkIn: true, checkOut: false },
      destinations: [],
      details: [
        { id: "10-1", time: "All Day", title: "Resort morning", note: "Last morning at resort", done: false },
        { id: "10-2", time: "16:00", title: "Head to airport", note: "", done: false },
        { id: "10-3", time: "18:10", title: "Flight to Cairo", note: "Arrive 19:10", done: false },
        { id: "10-4", time: "20:00", title: "Check in Novotel Airport", note: "Rest before departure", done: false },
      ]
    },
    {
      date: "2026-03-22", city: "Cairo → Chengdu", summary: "Fly home ✈️",
      transport: { type: "flight", detail: "3U3864", from: "Cairo CAI T2", to: "Chengdu TFU T1", depTime: "14:30", arrTime: "05:45+1" },
      accommodation: null,
      destinations: [],
      details: [
        { id: "11-1", time: "12:00", title: "Head to airport", note: "CAI Terminal 2", done: false },
        { id: "11-2", time: "14:30", title: "Flight 3U3864 to Chengdu", note: "Arrive Mar 23 05:45 TFU T1", done: false },
      ]
    },
  ]
};

const ALL_TRIPS = [EGYPT_TRIP];

// ─── Helpers ─────────────────────────────────────────────────────────────────
const fmt = (ds) => { const d = new Date(ds + "T00:00:00"); return d.toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" }); };
const daysBetween = (a, b) => Math.ceil((new Date(b) - new Date(a)) / 864e5) + 1;
const daysUntil = (ds) => { const n = new Date(); n.setHours(0,0,0,0); return Math.ceil((new Date(ds+"T00:00:00") - n) / 864e5); };
const tIcon = (t) => ({ flight: "✈️", drive: "🚗", train: "🚄", bus: "🚌" }[t] || "🚀");

// ─── UI Primitives ───────────────────────────────────────────────────────────
const Check = ({ checked, onChange }) => (
  <div onClick={e => { e.stopPropagation(); onChange(!checked); }} style={{
    width: 22, height: 22, borderRadius: 7, border: checked ? "none" : "2px solid #ccc",
    background: checked ? THEME.primary : "transparent", display: "flex", alignItems: "center",
    justifyContent: "center", cursor: "pointer", flexShrink: 0, transition: "all 0.2s"
  }}>{checked && <span style={{ color: "#fff", fontSize: 13, fontWeight: 700 }}>✓</span>}</div>
);

const BackBtn = ({ onClick, label }) => (
  <div onClick={onClick} style={{ display: "flex", alignItems: "center", gap: 4, cursor: "pointer", padding: "16px 20px 8px", color: THEME.primary, fontSize: 15, fontWeight: 500 }}>
    <span style={{ fontSize: 20 }}>‹</span> {label || "Back"}
  </div>
);

const SecHead = ({ children, s }) => (
  <div style={{ fontSize: 12, fontWeight: 700, color: "#999", textTransform: "uppercase", letterSpacing: 1.5, padding: "20px 20px 8px", ...s }}>{children}</div>
);

const Card = ({ children, style, onClick }) => (
  <div onClick={onClick} style={{
    background: THEME.card, borderRadius: 16, padding: 16, margin: "0 20px 10px",
    boxShadow: "0 1px 4px rgba(0,0,0,0.04)", cursor: onClick ? "pointer" : "default", ...style
  }}>{children}</div>
);

const Pill = ({ children, bg, color }) => (
  <span style={{ display: "inline-block", padding: "3px 10px", borderRadius: 20, fontSize: 11, fontWeight: 600, background: bg, color }}>{children}</span>
);

// ─── Tab Bars ────────────────────────────────────────────────────────────────
const TabBar = ({ tabs, active, onSelect }) => (
  <div style={{
    height: 82, background: "rgba(244,245,242,0.94)", backdropFilter: "blur(20px)",
    WebkitBackdropFilter: "blur(20px)", borderTop: "0.5px solid rgba(0,0,0,0.06)",
    display: "flex", alignItems: "flex-start", justifyContent: "space-around", paddingTop: 10,
  }}>
    {tabs.map(t => (
      <div key={t.id} onClick={() => onSelect(t.id)} style={{
        display: "flex", flexDirection: "column", alignItems: "center", gap: 3,
        cursor: "pointer", opacity: active === t.id ? 1 : 0.35, transition: "all 0.2s", minWidth: 52,
      }}>
        <span style={{ fontSize: 22 }}>{t.icon}</span>
        <span style={{ fontSize: 10, fontWeight: 600, letterSpacing: 0.3, color: active === t.id ? THEME.primary : THEME.text }}>{t.label}</span>
      </div>
    ))}
  </div>
);

const mainTabs = [
  { id: "trips", icon: "🏠", label: "Trips" },
  { id: "reminders", icon: "🔔", label: "Reminders" },
  { id: "settings", icon: "⚙️", label: "Settings" },
];

const tripTabs = [
  { id: "overview", icon: "📋", label: "Overview" },
  { id: "transport", icon: "✈️", label: "Transport" },
  { id: "accommodation", icon: "🏨", label: "Hotels" },
  { id: "destinations", icon: "📍", label: "Places" },
  { id: "info", icon: "ℹ️", label: "Info" },
];

// ─── Screens ─────────────────────────────────────────────────────────────────

const TripList = ({ onSelect }) => {
  const d = daysUntil(EGYPT_TRIP.startDate);
  return (
    <div>
      <div style={{ padding: "12px 20px 0" }}>
        <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>My Trips</div>
        <div style={{ fontSize: 14, color: THEME.textSec, marginTop: 2 }}>Plan it. Pack it. Go.</div>
      </div>
      <SecHead>Upcoming</SecHead>
      {ALL_TRIPS.map(trip => (
        <Card key={trip.id} onClick={() => onSelect(trip)} style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div style={{
            width: 56, height: 56, borderRadius: 14,
            background: `linear-gradient(135deg, ${THEME.primary}, ${THEME.primaryLight})`,
            display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, flexShrink: 0
          }}>{trip.emoji}</div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 17, fontWeight: 700, color: THEME.text }}>{trip.name}</div>
            <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>
              {fmt(trip.startDate)} – {fmt(trip.endDate)} · {daysBetween(trip.startDate, trip.endDate)} days
            </div>
          </div>
          <div style={{ textAlign: "right" }}>
            <div style={{ fontSize: 24, fontWeight: 800, color: THEME.primary }}>{d > 0 ? d : "Now"}</div>
            <div style={{ fontSize: 10, color: THEME.textTer, fontWeight: 500 }}>{d > 0 ? "days left" : ""}</div>
          </div>
        </Card>
      ))}
      <div style={{ padding: "6px 20px" }}>
        <div style={{
          border: `2px dashed ${THEME.primary}40`, borderRadius: 16, padding: 20,
          textAlign: "center", color: THEME.primary, fontSize: 14, fontWeight: 600, cursor: "pointer", opacity: 0.6
        }}>+ Add New Trip</div>
      </div>
    </div>
  );
};

const Reminders = () => (
  <div style={{ padding: "12px 20px 0" }}>
    <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>Reminders</div>
    <div style={{ fontSize: 14, color: THEME.textSec, marginTop: 2 }}>Upcoming tasks across all trips</div>
    <SecHead s={{ paddingLeft: 0 }}>Next 7 Days</SecHead>
    {[
      { icon: "🇪🇬", t: `Egypt trip starts in ${daysUntil(EGYPT_TRIP.startDate)} days`, sub: "Don't forget: visa photo, travel insurance" },
      { icon: "💰", t: "Prepare USD cash for visa", sub: "$25 exact change recommended" },
      { icon: "📱", t: "Download offline maps", sub: "Cairo, Luxor, Marsa Alam areas" },
    ].map((r, i) => (
      <Card key={i} style={{ margin: "0 0 10px", display: "flex", gap: 12, alignItems: "center" }}>
        <span style={{ fontSize: 22 }}>{r.icon}</span>
        <div>
          <div style={{ fontSize: 14, fontWeight: 600, color: THEME.text }}>{r.t}</div>
          <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 2 }}>{r.sub}</div>
        </div>
      </Card>
    ))}
  </div>
);

const Settings = () => (
  <div>
    <div style={{ padding: "12px 20px 10px" }}>
      <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>Settings</div>
    </div>
    {[
      { icon: "🌐", t: "Language", sub: "English" },
      { icon: "🔔", t: "Notifications", sub: "On" },
      { icon: "☁️", t: "Backup & Sync", sub: "iCloud" },
      { icon: "🎨", t: "Appearance", sub: "System" },
      { icon: "❓", t: "Help & Feedback", sub: "" },
      { icon: "📄", t: "About", sub: "v1.0" },
    ].map((item, i) => (
      <Card key={i} style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <span style={{ fontSize: 20 }}>{item.icon}</span>
        <div style={{ flex: 1, fontSize: 15, fontWeight: 500, color: THEME.text }}>{item.t}</div>
        <span style={{ fontSize: 13, color: THEME.textSec }}>{item.sub}</span>
        <span style={{ color: "#ccc" }}>›</span>
      </Card>
    ))}
  </div>
);

// ─── Trip Tabs ───────────────────────────────────────────────────────────────

const OverviewTab = ({ trip, onDay }) => (
  <div>
    <div style={{ padding: "10px 20px 6px" }}>
      <div style={{ fontSize: 26, fontWeight: 800, color: THEME.text }}>{trip.emoji} {trip.name}</div>
      <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{fmt(trip.startDate)} – {fmt(trip.endDate)} · {daysBetween(trip.startDate, trip.endDate)} days</div>
    </div>
    <SecHead>Daily Overview</SecHead>
    {trip.days.map((day, i) => (
      <Card key={day.date} onClick={() => onDay(i)} style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
        <div style={{
          width: 44, height: 44, borderRadius: 12, background: THEME.primaryMuted,
          display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0,
          fontSize: 15, fontWeight: 800, color: THEME.primary
        }}>D{i + 1}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ fontSize: 12, color: THEME.textSec, fontWeight: 600 }}>{fmt(day.date)}</div>
            <div style={{ fontSize: 11, color: THEME.textTer }}>{day.city}</div>
          </div>
          <div style={{ fontSize: 15, fontWeight: 600, color: THEME.text, marginTop: 4, lineHeight: 1.3 }}>{day.summary}</div>
          <div style={{ display: "flex", gap: 5, marginTop: 7, flexWrap: "wrap" }}>
            {day.transport && <Pill bg="#E3F2ED" color="#076C44">{tIcon(day.transport.type)} {day.transport.type}</Pill>}
            {day.accommodation?.checkIn && <Pill bg="#E8F5E9" color="#2E7D32">Check-in</Pill>}
            {day.destinations.length > 0 && <Pill bg="#FFF8E1" color="#F9A825">{day.destinations.length} place{day.destinations.length > 1 ? "s" : ""}</Pill>}
          </div>
        </div>
        <span style={{ color: "#ccc", fontSize: 18, marginTop: 12 }}>›</span>
      </Card>
    ))}
  </div>
);

const TransportTab = ({ trip }) => (
  <div>
    <div style={{ padding: "10px 20px 6px" }}>
      <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Transport</div>
      <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>All flights & transfers</div>
    </div>
    {trip.days.filter(d => d.transport).map((day) => (
      <Card key={day.date}>
        <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
          <div style={{ fontSize: 13, color: THEME.textSec, fontWeight: 600 }}>{fmt(day.date)}</div>
          <Pill bg={day.transport.type === "flight" ? "#E3F2ED" : "#FFF8E1"} color={day.transport.type === "flight" ? THEME.primary : "#F9A825"}>
            {tIcon(day.transport.type)} {day.transport.type.toUpperCase()}
          </Pill>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <div style={{ textAlign: "center", flex: 1 }}>
            <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>{day.transport.depTime || "—"}</div>
            <div style={{ fontSize: 11, color: THEME.textSec, marginTop: 3, lineHeight: 1.3 }}>{day.transport.from}</div>
          </div>
          <div style={{ flex: 0.8, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
            <div style={{ width: "100%", height: 2, background: `linear-gradient(90deg, ${THEME.primary}40, ${THEME.primary})`, borderRadius: 1, position: "relative" }}>
              <div style={{ position: "absolute", top: -9, left: "50%", transform: "translateX(-50%)", fontSize: 16, background: THEME.card, padding: "0 4px" }}>{tIcon(day.transport.type)}</div>
            </div>
            {day.transport.detail && <div style={{ fontSize: 11, color: THEME.textTer, fontWeight: 600 }}>{day.transport.detail}</div>}
          </div>
          <div style={{ textAlign: "center", flex: 1 }}>
            <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>{day.transport.arrTime || "—"}</div>
            <div style={{ fontSize: 11, color: THEME.textSec, marginTop: 3, lineHeight: 1.3 }}>{day.transport.to}</div>
          </div>
        </div>
      </Card>
    ))}
  </div>
);

const AccommodationTab = ({ trip }) => {
  const stays = [];
  let cur = null;
  trip.days.forEach(day => {
    if (!day.accommodation) return;
    if (cur && cur.name === day.accommodation.name) { cur.endDate = day.date; cur.nights++; }
    else { cur = { name: day.accommodation.name, address: day.accommodation.address, startDate: day.date, endDate: day.date, nights: 1 }; stays.push(cur); }
  });
  return (
    <div>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Accommodation</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{stays.length} hotels</div>
      </div>
      {stays.map((s, i) => (
        <Card key={i}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 16, fontWeight: 700, color: THEME.text }}>🏨 {s.name}</div>
              <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 4 }}>📍 {s.address}</div>
              <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 3 }}>📅 {fmt(s.startDate)} – {fmt(s.endDate)}</div>
            </div>
            <Pill bg={THEME.primaryFaint} color={THEME.primary}>{s.nights} night{s.nights > 1 ? "s" : ""}</Pill>
          </div>
          <div style={{ marginTop: 12, display: "flex", gap: 8 }}>
            <div style={{ flex: 1, background: "#f5f5f3", borderRadius: 10, padding: "10px 12px", fontSize: 12, color: "#666", cursor: "pointer", textAlign: "center", fontWeight: 600 }}>📋 Copy Address</div>
            <div style={{ flex: 1, background: "#f5f5f3", borderRadius: 10, padding: "10px 12px", fontSize: 12, color: "#666", cursor: "pointer", textAlign: "center", fontWeight: 600 }}>🗺️ Open Maps</div>
          </div>
        </Card>
      ))}
    </div>
  );
};

const DestinationsTab = ({ trip }) => {
  const total = trip.days.reduce((n, d) => n + d.destinations.length, 0);
  return (
    <div>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Places to Visit</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{total} destinations</div>
      </div>
      {trip.days.map((day, di) => day.destinations.length > 0 && (
        <div key={day.date}>
          <SecHead>Day {di + 1} · {fmt(day.date)}</SecHead>
          {day.destinations.map((dest, j) => (
            <Card key={j}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{ flex: 1 }}>
                  <div style={{ fontSize: 15, fontWeight: 700, color: THEME.text }}>
                    {dest.type === "attraction" ? "🏛️" : "🎪"} {dest.name}
                  </div>
                  <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 4 }}>📍 {dest.address}</div>
                  {dest.time && <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 2 }}>🕐 {dest.time}</div>}
                </div>
                {dest.ticketPrice && <Pill bg="#FFF8E1" color="#F9A825">{dest.ticketPrice}</Pill>}
              </div>
              {dest.notes && <div style={{ fontSize: 12, color: THEME.textTer, marginTop: 8, fontStyle: "italic" }}>💡 {dest.notes}</div>}
            </Card>
          ))}
        </div>
      ))}
    </div>
  );
};

const InfoTab = ({ trip }) => {
  const [items, setItems] = useState(trip.info);
  const toggle = (k) => setItems(p => ({ ...p, [k]: { ...p[k], done: !p[k].done } }));
  return (
    <div>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Essential Info</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>Things to prepare before departure</div>
      </div>
      {Object.entries(items).map(([k, item]) => (
        <Card key={k} style={{ display: "flex", gap: 12, alignItems: "flex-start", opacity: item.done ? 0.45 : 1, transition: "opacity 0.3s" }}>
          <Check checked={item.done} onChange={() => toggle(k)} />
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: THEME.text, textDecoration: item.done ? "line-through" : "none" }}>{item.title}</div>
            <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 5, lineHeight: 1.6 }}>{item.details}</div>
          </div>
        </Card>
      ))}
    </div>
  );
};

// ─── Day Detail (swipeable cards) ────────────────────────────────────────────
const DayDetail = ({ trip, dayIndex, onBack }) => {
  const day = trip.days[dayIndex];
  const [cur, setCur] = useState(0);
  const [details, setDetails] = useState(day.details);
  const [showDone, setShowDone] = useState(true);
  const ref = useRef(null);

  const toggle = (id) => setDetails(p => p.map(d => d.id === id ? { ...d, done: !d.done } : d));
  const visible = showDone ? details : details.filter(d => !d.done);

  const scrollTo = (i) => { if (ref.current) { ref.current.scrollTo({ left: i * 350, behavior: "smooth" }); setCur(i); } };
  const onScroll = () => { if (ref.current) setCur(Math.round(ref.current.scrollLeft / 350)); };

  const cardColors = [
    `linear-gradient(160deg, #FFFFFF 0%, #F8FAF8 100%)`,
    `linear-gradient(160deg, #F5FAF7 0%, #EDF5F0 100%)`,
    `linear-gradient(160deg, #FFFFFF 0%, #F6F9F7 100%)`,
  ];

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <BackBtn onClick={onBack} label="Overview" />
      <div style={{ padding: "4px 20px 0" }}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <div>
            <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Day {dayIndex + 1}</div>
            <div style={{ fontSize: 13, color: THEME.textSec }}>{fmt(day.date)} · {day.city}</div>
          </div>
          <div onClick={() => setShowDone(!showDone)} style={{
            fontSize: 12, color: THEME.primary, cursor: "pointer", fontWeight: 600,
            padding: "6px 14px", background: THEME.primaryFaint, borderRadius: 10
          }}>{showDone ? "Hide done" : "Show all"}</div>
        </div>
      </div>

      <div ref={ref} onScroll={onScroll} style={{
        flex: 1, display: "flex", overflowX: "auto", scrollSnapType: "x mandatory",
        padding: "16px 20px 0", WebkitOverflowScrolling: "touch",
        scrollbarWidth: "none", msOverflowStyle: "none",
      }}>
        <style>{`div::-webkit-scrollbar { display: none; }`}</style>
        {visible.map((item, i) => (
          <div key={item.id} style={{ minWidth: 350, maxWidth: 350, scrollSnapAlign: "center" }}>
            <div style={{
              width: 340, height: "100%", minHeight: 400,
              background: item.done ? "linear-gradient(160deg, #EDEEEB, #E6E7E3)" : cardColors[i % 3],
              borderRadius: 24, padding: 24, display: "flex", flexDirection: "column",
              position: "relative", overflow: "hidden",
              border: item.done ? "none" : `1px solid ${THEME.primary}10`,
              opacity: item.done ? 0.5 : 1, transition: "opacity 0.3s",
              boxShadow: item.done ? "none" : "0 4px 24px rgba(7,108,68,0.06)",
            }}>
              <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                <div style={{
                  background: THEME.primaryMuted, color: THEME.primary,
                  padding: "6px 16px", borderRadius: 12, fontSize: 14, fontWeight: 800
                }}>{item.time}</div>
                <Check checked={item.done} onChange={() => toggle(item.id)} />
              </div>
              <div style={{ marginTop: 36 }}>
                <div style={{
                  fontSize: 24, fontWeight: 800, color: THEME.text, lineHeight: 1.25,
                  textDecoration: item.done ? "line-through" : "none"
                }}>{item.title}</div>
                {item.note && <div style={{ fontSize: 14, color: THEME.textSec, marginTop: 14, lineHeight: 1.7 }}>{item.note}</div>}
              </div>
              <div style={{ marginTop: "auto", paddingTop: 20, display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                <div style={{ fontSize: 12, color: THEME.textTer, fontWeight: 500 }}>{i + 1} / {visible.length}</div>
              </div>
              <div style={{
                position: "absolute", bottom: -40, right: -40, width: 140, height: 140,
                borderRadius: "50%", background: THEME.primaryGhost
              }} />
              <div style={{
                position: "absolute", bottom: 20, right: 10, width: 60, height: 60,
                borderRadius: "50%", background: THEME.primaryGhost
              }} />
            </div>
          </div>
        ))}
      </div>

      <div style={{ display: "flex", justifyContent: "center", gap: 6, padding: "14px 0 6px" }}>
        {visible.map((_, i) => (
          <div key={i} onClick={() => scrollTo(i)} style={{
            width: cur === i ? 22 : 7, height: 7, borderRadius: 4,
            background: cur === i ? THEME.primary : "#ddd",
            transition: "all 0.3s", cursor: "pointer"
          }} />
        ))}
      </div>
    </div>
  );
};

// ─── Main ────────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState("home");
  const [trip, setTrip] = useState(null);
  const [tripTab, setTripTab] = useState("overview");
  const [dayIdx, setDayIdx] = useState(null);
  const [mainTab, setMainTab] = useState("trips");

  const openTrip = (t) => { setTrip(t); setScreen("trip"); setTripTab("overview"); setDayIdx(null); };
  const goHome = () => { setScreen("home"); setTrip(null); setDayIdx(null); setMainTab("trips"); };

  const inTrip = screen === "trip";
  const now = new Date();
  const time = now.toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: false });

  return (
    <div style={{
      width: 390, height: 844, borderRadius: 44, overflow: "hidden",
      background: THEME.bg, fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif",
      position: "relative", display: "flex", flexDirection: "column",
      boxShadow: "0 25px 80px rgba(0,0,0,0.2), 0 0 0 1px rgba(0,0,0,0.08)",
      margin: "20px auto",
    }}>
      {/* Notch */}
      <div style={{ height: 54, display: "flex", alignItems: "flex-end", justifyContent: "center", padding: "0 28px 8px" }}>
        <span style={{ fontSize: 14, fontWeight: 600, color: THEME.text }}>{time}</span>
        <span style={{ flex: 1 }} />
        <span style={{ fontSize: 11 }}>📶 🔋</span>
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: "auto", overflowX: "hidden", WebkitOverflowScrolling: "touch" }}>
        {screen === "home" && mainTab === "trips" && <TripList onSelect={openTrip} />}
        {screen === "home" && mainTab === "reminders" && <Reminders />}
        {screen === "home" && mainTab === "settings" && <Settings />}

        {inTrip && dayIdx !== null && <DayDetail trip={trip} dayIndex={dayIdx} onBack={() => setDayIdx(null)} />}
        {inTrip && dayIdx === null && (
          <>
            <BackBtn onClick={goHome} label="My Trips" />
            {tripTab === "overview" && <OverviewTab trip={trip} onDay={i => setDayIdx(i)} />}
            {tripTab === "transport" && <TransportTab trip={trip} />}
            {tripTab === "accommodation" && <AccommodationTab trip={trip} />}
            {tripTab === "destinations" && <DestinationsTab trip={trip} />}
            {tripTab === "info" && <InfoTab trip={trip} />}
          </>
        )}
      </div>

      {/* Tab Bar */}
      <TabBar
        tabs={inTrip ? tripTabs : mainTabs}
        active={inTrip ? tripTab : mainTab}
        onSelect={id => { if (inTrip) { setTripTab(id); setDayIdx(null); } else setMainTab(id); }}
      />

      {/* Home indicator */}
      <div style={{ height: 8, display: "flex", justifyContent: "center", paddingBottom: 6, background: "rgba(244,245,242,0.94)" }}>
        <div style={{ width: 134, height: 5, borderRadius: 3, background: "#00000020" }} />
      </div>
    </div>
  );
}
