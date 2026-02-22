import { useState, useRef, useEffect } from "react";

const THEME = {
  primary: "#076C44", primaryLight: "#0A8A58", primaryMuted: "#076C4430",
  primaryFaint: "#076C4412", primaryGhost: "#076C4408",
  bg: "#F4F5F2", card: "#FFFFFF", text: "#1A1A1A", textSec: "#888888", textTer: "#AAAAAA",
  transport: "#2196F3", hotel: "#9C27B0", attraction: "#F9A825",
  restaurant: "#076C44", activity: "#00BCD4", other: "#9E9E9E",
};
const typeColor = (t) => ({ flight: THEME.transport, drive: THEME.transport, train: THEME.transport, bus: THEME.transport, hotel: THEME.hotel, attraction: "#F9A825", restaurant: THEME.primary, activity: THEME.activity }[t] || THEME.other);
const typeIcon = (t) => ({ flight: "✈️", drive: "🚗", train: "🚄", bus: "🚌", hotel: "🏨", attraction: "🏛️", restaurant: "🍽️", activity: "🎪" }[t] || "📝");

// Emoji quick-select: CN, NZ, SG first, then popular travel destinations
const COMMON_EMOJIS = ["🇨🇳","🇳🇿","🇸🇬","🇯🇵","🇰🇷","🇺🇸","🇬🇧","🇫🇷","🇩🇪","🇮🇹","🇪🇸","🇹🇭","🇦🇪","🇪🇬","🇲🇦","🇹🇷","🇬🇷","🇵🇹","🇦🇺","✈️","🏖️","🏔️","🗺️","🧳"];

const EGYPT_TRIP = {
  id: "egypt-2026", name: "Egypt", emoji: "🇪🇬", startDate: "2026-03-12", endDate: "2026-03-23",
  info: [
    { id: "i1", title: "Visa on Arrival", details: "USD $25, single entry. Bring passport photo." },
    { id: "i2", title: "SIM Card", details: "Vodafone/Orange at Cairo Airport. ~200 EGP for 10GB/15 days." },
    { id: "i3", title: "Currency Exchange", details: "EGP. ~1 USD ≈ 50 EGP. Carry small bills for tips." },
    { id: "i4", title: "Emergency Contacts", details: "Police: 122 | Ambulance: 123 | Embassy: +20-2-27361219" },
    { id: "i5", title: "Travel Insurance", details: "Keep policy number & hotline screenshot offline." },
  ],
  days: [
    { date: "2026-03-12", city: "Cairo", summary: "Arrive Cairo + Egyptian Museum",
      transports: [{ id: "t1", type: "flight", detail: "3U3863", from: "Chengdu TFU T1", to: "Cairo CAI T2", depTime: "01:40", arrTime: "06:30" }],
      accommodation: { id: "a1", name: "Ramses Hilton", address: "1115 Corniche El Nil, Cairo", checkIn: true },
      destinations: [{ id: "p1", name: "The Egyptian Museum in Cairo", type: "attraction", time: "14:00-17:00", address: "Tahrir Square, Cairo", ticketPrice: "450 EGP", notes: "Old museum, still worth visiting" }],
      timeline: [
        { id: "tl1", time: "06:30", title: "Arrive Cairo Airport T2", note: "Visa → SIM → Currency exchange", type: "flight", linkedId: "t1" },
        { id: "tl2", time: "08:30", title: "Transfer to Ramses Hilton", note: "Taxi/Uber ~250 EGP, 30min", type: "drive", linkedId: null },
        { id: "tl3", time: "09:00", title: "Check-in · Ramses Hilton", note: "", type: "hotel", linkedId: "a1" },
        { id: "tl4", time: "14:00", title: "🏛️ The Egyptian Museum", note: "Tahrir Sq · 450 EGP", type: "attraction", linkedId: "p1" },
        { id: "tl5", time: "19:00", title: "Dinner", note: "Explore nearby restaurants", type: "restaurant", linkedId: null },
      ] },
    { date: "2026-03-13", city: "Cairo → Luxor", summary: "Giza + Grand Museum → Fly to Luxor",
      transports: [{ id: "t2", type: "flight", detail: "Flight", from: "Cairo", to: "Luxor", depTime: "21:00", arrTime: "22:40" }],
      accommodation: { id: "a2", name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: true },
      destinations: [
        { id: "p2", name: "GIZA Pyramids", type: "attraction", time: "08:00-12:00", address: "Al Haram, Giza", ticketPrice: "540 EGP", notes: "Go early" },
        { id: "p3", name: "Grand Egyptian Museum", type: "attraction", time: "13:00-17:00", address: "Giza", ticketPrice: "600 EGP", notes: "Allow 3-4 hours" }
      ],
      timeline: [
        { id: "tl6", time: "07:00", title: "Head to Giza", note: "~30min from hotel", type: "drive", linkedId: null },
        { id: "tl7", time: "08:00", title: "🏛️ GIZA Pyramids", note: "540 EGP · Camel rides optional", type: "attraction", linkedId: "p2" },
        { id: "tl8", time: "12:00", title: "Lunch near Giza", note: "", type: "restaurant", linkedId: null },
        { id: "tl9", time: "13:00", title: "🏛️ Grand Egyptian Museum", note: "600 EGP · Brand new", type: "attraction", linkedId: "p3" },
        { id: "tl10", time: "17:00", title: "Return & pack", note: "Head to airport", type: "other", linkedId: null },
        { id: "tl11", time: "21:00", title: "Flight to Luxor", note: "Arrive 22:40", type: "flight", linkedId: "t2" },
        { id: "tl12", time: "22:40", title: "Check-in · Sonesta Luxor", note: "", type: "hotel", linkedId: "a2" },
      ] },
    { date: "2026-03-14", city: "Luxor", summary: "Karnak Temple + Ferry Tour", transports: [],
      accommodation: { id: "a2b", name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false },
      destinations: [
        { id: "p4", name: "Karnak Temple", type: "attraction", time: "08:00-11:00", address: "Karnak, Luxor", ticketPrice: "300 EGP", notes: "Largest ancient religious site" },
        { id: "p5", name: "Ferry Tour", type: "activity", time: "15:00-17:00", address: "Nile River, Luxor", ticketPrice: "~100 EGP", notes: "Sunset felucca" }
      ],
      timeline: [
        { id: "tl13", time: "08:00", title: "🏛️ Karnak Temple", note: "300 EGP · Huge complex", type: "attraction", linkedId: "p4" },
        { id: "tl14", time: "12:00", title: "Lunch", note: "", type: "restaurant", linkedId: null },
        { id: "tl15", time: "15:00", title: "🎪 Nile Ferry Tour", note: "Felucca · Sunset", type: "activity", linkedId: "p5" },
      ] },
    { date: "2026-03-15", city: "Luxor", summary: "Hot Air Balloon + Luxor Temple + Sphinxes", transports: [],
      accommodation: { id: "a2c", name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false },
      destinations: [
        { id: "p6", name: "Hot Air Balloon", type: "activity", time: "05:00-07:00", address: "West Bank, Luxor", ticketPrice: "~$80-150", notes: "Book ahead" },
        { id: "p7", name: "Luxor Temple", type: "attraction", time: "10:00-12:00", address: "Luxor City Center", ticketPrice: "260 EGP", notes: "" },
        { id: "p8", name: "Avenue of Sphinxes", type: "attraction", time: "12:00-13:00", address: "Karnak to Luxor Temple", ticketPrice: "Free", notes: "2.7km" }
      ],
      timeline: [
        { id: "tl16", time: "04:30", title: "🎪 Hot Air Balloon", note: "Sunrise over West Bank", type: "activity", linkedId: "p6" },
        { id: "tl17", time: "07:00", title: "Return & Breakfast", note: "", type: "other", linkedId: null },
        { id: "tl18", time: "10:00", title: "🏛️ Luxor Temple", note: "260 EGP", type: "attraction", linkedId: "p7" },
        { id: "tl19", time: "12:00", title: "🏛️ Avenue of Sphinxes", note: "Free · Walk", type: "attraction", linkedId: "p8" },
      ] },
    { date: "2026-03-16", city: "Luxor", summary: "Valley of Kings + Hatshepsut + Memnon", transports: [],
      accommodation: { id: "a2d", name: "Sonesta St. George Hotel - Luxor", address: "Luxor City, Luxor", checkIn: false },
      destinations: [
        { id: "p9", name: "Valley of the Kings", type: "attraction", time: "07:00-10:00", address: "West Bank", ticketPrice: "600 EGP (3 tombs)", notes: "No photos inside" },
        { id: "p10", name: "Temple of Hatshepsut", type: "attraction", time: "10:30-12:00", address: "West Bank", ticketPrice: "240 EGP", notes: "Terraced temple" },
        { id: "p11", name: "Colossi of Memnon", type: "attraction", time: "12:30-13:00", address: "West Bank", ticketPrice: "Free", notes: "Quick stop" }
      ],
      timeline: [
        { id: "tl20", time: "07:00", title: "🏛️ Valley of the Kings", note: "600 EGP · Go early!", type: "attraction", linkedId: "p9" },
        { id: "tl21", time: "10:30", title: "🏛️ Temple of Hatshepsut", note: "240 EGP", type: "attraction", linkedId: "p10" },
        { id: "tl22", time: "12:30", title: "🏛️ Colossi of Memnon", note: "Free", type: "attraction", linkedId: "p11" },
        { id: "tl23", time: "13:30", title: "Lunch & Rest", note: "Last full day in Luxor", type: "restaurant", linkedId: null },
      ] },
    { date: "2026-03-17", city: "Luxor → Marsa Alam", summary: "Drive to Marsa Alam",
      transports: [{ id: "t3", type: "drive", detail: "Drive", from: "Luxor", to: "Marsa Alam", depTime: "09:30", arrTime: "14:30" }],
      accommodation: { id: "a3", name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: true },
      destinations: [],
      timeline: [
        { id: "tl24", time: "09:00", title: "Check-out · Sonesta Luxor", note: "", type: "hotel", linkedId: "a2" },
        { id: "tl25", time: "09:30", title: "Drive to Marsa Alam", note: "~4-5 hours", type: "drive", linkedId: "t3" },
        { id: "tl26", time: "14:30", title: "Check-in · JAZ Maraya", note: "Resort!", type: "hotel", linkedId: "a3" },
      ] },
    { date: "2026-03-18", city: "Marsa Alam", summary: "Beach & Resort Day", transports: [],
      accommodation: { id: "a3b", name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false },
      destinations: [], timeline: [{ id: "tl27", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", type: "activity", linkedId: null }] },
    { date: "2026-03-19", city: "Marsa Alam", summary: "Beach & Resort Day", transports: [],
      accommodation: { id: "a3c", name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false },
      destinations: [], timeline: [{ id: "tl28", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", type: "activity", linkedId: null }] },
    { date: "2026-03-20", city: "Marsa Alam", summary: "Beach & Resort Day", transports: [],
      accommodation: { id: "a3d", name: "JAZ Elite Maraya", address: "Marsa Alam, Red Sea", checkIn: false },
      destinations: [], timeline: [{ id: "tl29", time: "All Day", title: "Resort & Beach", note: "Relax, snorkel, dive", type: "activity", linkedId: null }] },
    { date: "2026-03-21", city: "Marsa Alam → Cairo", summary: "Fly back to Cairo",
      transports: [{ id: "t4", type: "flight", detail: "Flight", from: "Marsa Alam", to: "Cairo", depTime: "18:10", arrTime: "19:10" }],
      accommodation: { id: "a4", name: "Novotel Cairo Airport Hotel", address: "Cairo Airport", checkIn: true },
      destinations: [],
      timeline: [
        { id: "tl30", time: "All Day", title: "Resort morning", note: "Last beach morning", type: "activity", linkedId: null },
        { id: "tl31", time: "16:00", title: "Head to airport", note: "", type: "drive", linkedId: null },
        { id: "tl32", time: "18:10", title: "Flight to Cairo", note: "Arrive 19:10", type: "flight", linkedId: "t4" },
        { id: "tl33", time: "20:00", title: "Check-in · Novotel Cairo Airport", note: "", type: "hotel", linkedId: "a4" },
      ] },
    { date: "2026-03-22", city: "Cairo → Chengdu", summary: "Fly home ✈️",
      transports: [{ id: "t5", type: "flight", detail: "3U3864", from: "Cairo CAI T2", to: "Chengdu TFU T1", depTime: "14:30", arrTime: "05:45+1" }],
      accommodation: null, destinations: [],
      timeline: [
        { id: "tl34", time: "11:00", title: "Check-out · Novotel", note: "", type: "hotel", linkedId: "a4" },
        { id: "tl35", time: "12:00", title: "Head to airport", note: "CAI Terminal 2", type: "drive", linkedId: null },
        { id: "tl36", time: "14:30", title: "Flight 3U3864 to Chengdu", note: "Arrive Mar 23 05:45 TFU T1", type: "flight", linkedId: "t5" },
      ] },
  ]
};
const ALL_TRIPS = [EGYPT_TRIP];
const fmt = (ds) => new Date(ds + "T00:00:00").toLocaleDateString("en-US", { weekday: "short", month: "short", day: "numeric" });
const fmtShort = (ds) => new Date(ds + "T00:00:00").toLocaleDateString("en-US", { month: "short", day: "numeric" });
const daysBetween = (a, b) => Math.ceil((new Date(b) - new Date(a)) / 864e5) + 1;
const daysUntil = (ds) => { const n = new Date(); n.setHours(0,0,0,0); return Math.ceil((new Date(ds+"T00:00:00") - n) / 864e5); };
const tIcon = (t) => ({ flight: "✈️", drive: "🚗", train: "🚄", bus: "🚌" }[t] || "🚀");

// ─── UI Primitives ───────────────────────────────────────────────────────────
const Check = ({ checked, onChange, color, size }) => {
  const s = size || 22;
  return (
    <div onClick={e => { e.stopPropagation(); onChange(!checked); }} style={{
      width: s, height: s, borderRadius: s * 0.32, border: checked ? "none" : `2px solid ${color || "#ccc"}`,
      background: checked ? (color || THEME.primary) : "transparent", display: "flex", alignItems: "center",
      justifyContent: "center", cursor: "pointer", flexShrink: 0, transition: "all 0.2s"
    }}>{checked && <span style={{ color: "#fff", fontSize: s * 0.59, fontWeight: 700 }}>✓</span>}</div>
  );
};

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
  <span style={{ display: "inline-block", padding: "3px 10px", borderRadius: 20, fontSize: 11, fontWeight: 600, background: bg, color, whiteSpace: "nowrap" }}>{children}</span>
);

const AddBtn = ({ onClick }) => (
  <div onClick={onClick} style={{
    position: "absolute", top: 14, right: 20, width: 30, height: 30, borderRadius: 9,
    background: THEME.primary, display: "flex", alignItems: "center", justifyContent: "center",
    cursor: "pointer", boxShadow: "0 2px 8px rgba(7,108,68,0.25)", zIndex: 10,
  }}><span style={{ color: "#fff", fontSize: 18, fontWeight: 300, lineHeight: 1 }}>+</span></div>
);

const Sheet = ({ title, onClose, children }) => (
  <div style={{ position: "absolute", inset: 0, zIndex: 100, display: "flex", flexDirection: "column", justifyContent: "flex-end" }}>
    <div onClick={onClose} style={{ flex: 1, background: "rgba(0,0,0,0.3)" }} />
    <div style={{ background: THEME.bg, borderRadius: "20px 20px 0 0", maxHeight: "80%", overflow: "auto", padding: "0 0 30px" }}>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", padding: "16px 20px 12px", borderBottom: "1px solid #eee" }}>
        <span style={{ fontSize: 17, fontWeight: 700, color: THEME.text }}>{title}</span>
        <span onClick={onClose} style={{ fontSize: 14, color: THEME.primary, cursor: "pointer", fontWeight: 600 }}>Cancel</span>
      </div>
      <div style={{ padding: "16px 20px" }}>{children}</div>
    </div>
  </div>
);

const FormField = ({ label, placeholder, multiline, children }) => (
  <div style={{ marginBottom: 14 }}>
    <div style={{ fontSize: 11, fontWeight: 700, color: THEME.textSec, marginBottom: 5, textTransform: "uppercase", letterSpacing: 0.8 }}>{label}</div>
    {children || <div style={{ width: "100%", padding: "10px 12px", borderRadius: 10, border: "1px solid #ddd", fontSize: 14, background: "#fff", color: "#bbb", boxSizing: "border-box", minHeight: multiline ? 60 : "auto" }}>{placeholder}</div>}
  </div>
);

const SaveBtn = ({ onClick, label }) => (
  <div onClick={onClick} style={{ background: THEME.primary, color: "#fff", padding: "12px", borderRadius: 12, textAlign: "center", fontSize: 15, fontWeight: 700, cursor: "pointer", marginTop: 6 }}>{label || "Save"}</div>
);

const ViewDetailsBtn = ({ color }) => (
  <div style={{ marginTop: 10, textAlign: "center", fontSize: 12, color: color || THEME.primary, fontWeight: 600, cursor: "pointer", padding: "8px", background: (color || THEME.primary) + "08", borderRadius: 10 }}>View details ›</div>
);

const TabBar = ({ tabs, active, onSelect }) => (
  <div style={{ height: 82, background: "rgba(244,245,242,0.94)", backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)", borderTop: "0.5px solid rgba(0,0,0,0.06)", display: "flex", alignItems: "flex-start", justifyContent: "space-around", paddingTop: 10 }}>
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
  { id: "todo", icon: "✅", label: "Todo" },
  { id: "settings", icon: "⚙️", label: "Settings" },
];
const tripTabs = [
  { id: "overview", icon: "📋", label: "Overview" },
  { id: "transport", icon: "✈️", label: "Transport" },
  { id: "accommodation", icon: "🏨", label: "Hotels" },
  { id: "destinations", icon: "📍", label: "Places" },
  { id: "info", icon: "ℹ️", label: "Info" },
];

// ─── Trip List ───────────────────────────────────────────────────────────────
// Changes from MVP1:
// • Dashed "Add New Trip" card removed — only the + button in top-right adds trips
// • Trip cards support swipe-left to delete (shown as ✕ hint on right)
// • NewTripSheet: emoji field + horizontal emoji quick-select row (🇨🇳🇳🇿🇸🇬 first)
// • Date pickers use compact inline style
const TripList = ({ onSelect }) => {
  const [showAdd, setShowAdd] = useState(false);
  const [emoji, setEmoji] = useState("");
  const d = daysUntil(EGYPT_TRIP.startDate);
  return (
    <div style={{ position: "relative", minHeight: "100%" }}>
      <div style={{ padding: "12px 20px 0" }}>
        <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>My Trips</div>
        <div style={{ fontSize: 14, color: THEME.textSec, marginTop: 2 }}>Plan it. Pack it. Go.</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />
      <SecHead>Upcoming</SecHead>
      {ALL_TRIPS.map(trip => (
        // Swipe-left to reveal delete — simulated as subtle ✕ on right edge
        <div key={trip.id} style={{ position: "relative" }}>
          <Card onClick={() => onSelect(trip)} style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <div style={{ width: 56, height: 56, borderRadius: 14, background: `linear-gradient(135deg, ${THEME.primary}, ${THEME.primaryLight})`, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, flexShrink: 0 }}>{trip.emoji}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 17, fontWeight: 700, color: THEME.text }}>{trip.name}</div>
              <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{fmt(trip.startDate)} – {fmt(trip.endDate)}</div>
              <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 1 }}>{daysBetween(trip.startDate, trip.endDate)} days</div>
            </div>
            <div style={{ textAlign: "right" }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: THEME.primary }}>{d > 0 ? d : "Now"}</div>
              <div style={{ fontSize: 10, color: THEME.textTer, fontWeight: 500 }}>{d > 0 ? "days left" : ""}</div>
            </div>
          </Card>
          {/* Swipe-to-delete indicator */}
          <div style={{ position: "absolute", right: 20, top: "50%", transform: "translateY(-50%)", fontSize: 11, color: "#FF3B30", fontWeight: 600, opacity: 0.35, pointerEvents: "none" }}>← swipe</div>
        </div>
      ))}

      {showAdd && (
        <Sheet title="New Trip" onClose={() => setShowAdd(false)}>
          <FormField label="Trip Name" placeholder="e.g. Japan Spring" />

          {/* Emoji field + quick-select row */}
          <FormField label="Emoji">
            <div style={{ width: "100%", padding: "10px 12px", borderRadius: 10, border: "1px solid #ddd", fontSize: 22, background: "#fff", marginBottom: 8 }}>
              {emoji || <span style={{ color: "#ccc", fontSize: 14 }}>Tap a flag below or type</span>}
            </div>
            <div style={{ display: "flex", gap: 6, overflowX: "auto", paddingBottom: 4 }}>
              {COMMON_EMOJIS.map(e => (
                <span key={e} onClick={() => setEmoji(e)} style={{
                  fontSize: 24, cursor: "pointer", flexShrink: 0, padding: "4px 2px",
                  borderRadius: 8, background: emoji === e ? THEME.primaryFaint : "transparent",
                  border: emoji === e ? `1.5px solid ${THEME.primary}40` : "1.5px solid transparent",
                }}>{e}</span>
              ))}
            </div>
          </FormField>

          {/* Compact date pickers side-by-side */}
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField label="Start Date">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>📅 Mar 12, 2026</div>
              </FormField>
            </div>
            <div style={{ flex: 1 }}>
              <FormField label="End Date">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>📅 Mar 23, 2026</div>
              </FormField>
            </div>
          </div>
          <SaveBtn onClick={() => { setShowAdd(false); setEmoji(""); }} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Todo (formerly Reminders) ───────────────────────────────────────────────
// Redesigned as two sections:
//   1. "Trip Reminders" — auto-generated from trips (read-only, no delete)
//   2. "My Tasks" — manual TaskItems: checkbox, tap-to-edit title, swipe-to-delete
// + button in top-right opens inline text input to add a new task
const TodoList = () => {
  const [tasks, setTasks] = useState([
    { id: "tk1", title: "Book airport transfer", isDone: false },
    { id: "tk2", title: "Print hotel confirmations", isDone: false },
    { id: "tk3", title: "Notify bank of travel dates", isDone: true },
  ]);
  const [showInlineAdd, setShowInlineAdd] = useState(false);
  const [newText, setNewText] = useState("");
  const [editingId, setEditingId] = useState(null);

  const addTask = () => {
    if (!newText.trim()) return;
    setTasks(p => [...p, { id: Date.now().toString(), title: newText.trim(), isDone: false }]);
    setNewText(""); setShowInlineAdd(false);
  };
  const toggleTask = (id) => setTasks(p => p.map(t => t.id === id ? { ...t, isDone: !t.isDone } : t));
  const deleteTask = (id) => setTasks(p => p.filter(t => t.id !== id));
  const updateTitle = (id, title) => setTasks(p => p.map(t => t.id === id ? { ...t, title } : t));

  const d = daysUntil(EGYPT_TRIP.startDate);
  // Auto-generated trip reminders
  const tripReminders = [
    { icon: EGYPT_TRIP.emoji, title: `${EGYPT_TRIP.name} trip in ${d} days`, sub: "Check visa, travel insurance, and offline maps" },
    { icon: "💉", title: "Vaccinations", sub: "Hepatitis A recommended for Egypt" },
    { icon: "💳", title: "Notify bank", sub: "Enable international transactions" },
  ];

  return (
    <div style={{ position: "relative", minHeight: "100%" }}>
      <div style={{ padding: "12px 20px 0" }}>
        <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>Todo</div>
        <div style={{ fontSize: 14, color: THEME.textSec, marginTop: 2 }}>Stay on top of your trip</div>
      </div>
      <AddBtn onClick={() => { setShowInlineAdd(true); setEditingId(null); }} />

      {/* Trip Reminders — auto, read-only */}
      <SecHead>Trip Reminders</SecHead>
      {tripReminders.map((r, i) => (
        <Card key={i} style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
          <span style={{ fontSize: 22, flexShrink: 0 }}>{r.icon}</span>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: THEME.text }}>{r.title}</div>
            <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 2 }}>{r.sub}</div>
          </div>
        </Card>
      ))}

      {/* My Tasks — manual, with checkboxes + delete */}
      <SecHead>My Tasks</SecHead>

      {/* Inline add input */}
      {showInlineAdd && (
        <div style={{ margin: "0 20px 10px", background: THEME.card, borderRadius: 16, padding: "12px 14px", display: "flex", gap: 10, alignItems: "center", boxShadow: "0 1px 4px rgba(0,0,0,0.06)" }}>
          <input
            autoFocus
            value={newText}
            onChange={e => setNewText(e.target.value)}
            onKeyDown={e => e.key === "Enter" && addTask()}
            placeholder="New task..."
            style={{ flex: 1, border: "none", outline: "none", fontSize: 15, color: THEME.text, background: "transparent" }}
          />
          <span onClick={addTask} style={{ color: THEME.primary, fontWeight: 700, fontSize: 14, cursor: "pointer" }}>Add</span>
          <span onClick={() => { setShowInlineAdd(false); setNewText(""); }} style={{ color: THEME.textSec, fontSize: 13, cursor: "pointer" }}>Cancel</span>
        </div>
      )}

      {tasks.map(task => (
        <div key={task.id} style={{ position: "relative" }}>
          <Card style={{ display: "flex", gap: 12, alignItems: "center", opacity: task.isDone ? 0.5 : 1, transition: "opacity 0.3s" }}>
            <Check checked={task.isDone} onChange={() => toggleTask(task.id)} color={THEME.primary} size={22} />
            <div style={{ flex: 1 }}>
              {editingId === task.id && !task.isDone ? (
                <input
                  autoFocus
                  value={task.title}
                  onChange={e => updateTitle(task.id, e.target.value)}
                  onBlur={() => setEditingId(null)}
                  onKeyDown={e => e.key === "Enter" && setEditingId(null)}
                  style={{ width: "100%", border: "none", outline: "none", fontSize: 15, fontWeight: 500, color: THEME.text, background: "transparent" }}
                />
              ) : (
                <div
                  onClick={() => { if (!task.isDone) setEditingId(task.id); }}
                  style={{ fontSize: 15, fontWeight: 500, color: THEME.text, textDecoration: task.isDone ? "line-through" : "none", cursor: task.isDone ? "default" : "text" }}
                >{task.title}</div>
              )}
            </div>
            {/* Swipe-to-delete simulated as ✕ */}
            <div onClick={() => deleteTask(task.id)} style={{ width: 28, height: 28, borderRadius: 8, background: "#FF3B3010", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer", flexShrink: 0 }}>
              <span style={{ fontSize: 14, color: "#FF3B30", fontWeight: 700 }}>✕</span>
            </div>
          </Card>
        </div>
      ))}

      {tasks.length === 0 && !showInlineAdd && (
        <div style={{ textAlign: "center", padding: "30px 20px", color: THEME.textTer, fontSize: 14 }}>
          No tasks yet — tap + to add one
        </div>
      )}
    </div>
  );
};

// ─── Settings ────────────────────────────────────────────────────────────────
// Static non-functional menu (all items are display-only placeholders for MVP3)
const Settings = () => (
  <div>
    <div style={{ padding: "12px 20px 10px" }}>
      <div style={{ fontSize: 30, fontWeight: 800, color: THEME.text, letterSpacing: -0.8 }}>Settings</div>
    </div>
    {[
      { icon: "🌐", t: "Language",       sub: "English" },
      { icon: "🔔", t: "Notifications",  sub: "On" },
      { icon: "☁️", t: "Backup & Sync",  sub: "iCloud" },
      { icon: "🎨", t: "Appearance",     sub: "System" },
      { icon: "❓", t: "Help & Feedback", sub: "" },
      { icon: "📄", t: "About",          sub: "v1.0" },
    ].map((item, i) => (
      <Card key={i} style={{ display: "flex", alignItems: "center", gap: 12 }}>
        <span style={{ fontSize: 20, width: 26, textAlign: "center" }}>{item.icon}</span>
        <div style={{ flex: 1, fontSize: 15, fontWeight: 500, color: THEME.text }}>{item.t}</div>
        {item.sub ? <span style={{ fontSize: 13, color: THEME.textSec }}>{item.sub}</span> : null}
        <span style={{ color: "#ccc" }}>›</span>
      </Card>
    ))}
  </div>
);

// ─── Overview Tab ────────────────────────────────────────────────────────────
// Pills use flexWrap so each pill stays whole — no mid-word breaks
const OverviewTab = ({ trip, onDay }) => (
  <div>
    <div style={{ padding: "10px 20px 6px" }}>
      <div style={{ fontSize: 26, fontWeight: 800, color: THEME.text }}>{trip.emoji} {trip.name}</div>
      <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>
        {fmt(trip.startDate)} – {fmt(trip.endDate)} ·{" "}
        <span style={{ background: THEME.primary + "18", color: THEME.primary, padding: "1px 8px", borderRadius: 8, fontWeight: 700 }}>
          {daysBetween(trip.startDate, trip.endDate)} days
        </span>
      </div>
    </div>
    <SecHead>Daily Overview</SecHead>
    {trip.days.map((day, i) => (
      <Card key={day.date} onClick={() => onDay(i)} style={{ display: "flex", gap: 12, alignItems: "flex-start" }}>
        <div style={{ width: 44, height: 44, borderRadius: 12, background: THEME.primaryMuted, display: "flex", alignItems: "center", justifyContent: "center", flexShrink: 0, fontSize: 15, fontWeight: 800, color: THEME.primary }}>D{i + 1}</div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <div style={{ fontSize: 12, color: THEME.textSec, fontWeight: 600 }}>{fmt(day.date)}</div>
            <div style={{ fontSize: 11, color: THEME.text, fontWeight: 600 }}>{day.city}</div>
          </div>
          <div style={{ fontSize: 15, fontWeight: 600, color: THEME.text, marginTop: 4, lineHeight: 1.3 }}>{day.summary}</div>
          {/* Pills wrap to next row as whole unit — no mid-word breaks */}
          <div style={{ display: "flex", gap: 5, marginTop: 7, flexWrap: "wrap" }}>
            {day.transports.length > 0 && <Pill bg={THEME.transport + "18"} color={THEME.transport}>{tIcon(day.transports[0].type)} {day.transports[0].type}</Pill>}
            {day.accommodation?.checkIn && <Pill bg={THEME.hotel + "15"} color={THEME.hotel}>🏨 Check-in</Pill>}
            {day.destinations.length > 0 && <Pill bg="#FFF8E1" color="#F9A825">📍 {day.destinations.length} place{day.destinations.length > 1 ? "s" : ""}</Pill>}
          </div>
        </div>
        <span style={{ color: "#ccc", fontSize: 18, marginTop: 12 }}>›</span>
      </Card>
    ))}
  </div>
);

// ─── Transport Tab ───────────────────────────────────────────────────────────
// Changes:
// • Add form: Day + Type in one horizontal row; day format "Day 1, Mar 12"
// • Adding transport auto-creates a TimelineItem in Daily (linkedId = transport.id)
// • Swipe-to-delete on transport cards also removes linked Daily item
const TransportTab = ({ trip }) => {
  const [showAdd, setShowAdd] = useState(false);
  const transports = trip.days.flatMap((d, di) => d.transports.map(t => ({ ...t, date: d.date, dayIdx: di })));
  return (
    <div style={{ position: "relative" }}>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Transport</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>All flights & transfers</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />
      {transports.map(tr => (
        <Card key={tr.id}>
          <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 12 }}>
            <div style={{ fontSize: 13, color: THEME.textSec, fontWeight: 600 }}>Day {tr.dayIdx + 1}, {fmtShort(tr.date)}</div>
            <Pill bg={THEME.transport + "18"} color={THEME.transport}>
              {tIcon(tr.type)} {tr.type.toUpperCase()}
            </Pill>
          </div>
          <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
            <div style={{ textAlign: "center", flex: 1 }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>{tr.depTime || "—"}</div>
              <div style={{ fontSize: 11, color: THEME.textSec, marginTop: 3, lineHeight: 1.3 }}>{tr.from}</div>
            </div>
            <div style={{ flex: 0.8, display: "flex", flexDirection: "column", alignItems: "center", gap: 6 }}>
              <div style={{ width: "100%", height: 2, background: `linear-gradient(90deg, ${THEME.primary}40, ${THEME.primary})`, borderRadius: 1, position: "relative" }}>
                <div style={{ position: "absolute", top: -9, left: "50%", transform: "translateX(-50%)", fontSize: 16, background: THEME.card, padding: "0 4px" }}>{tIcon(tr.type)}</div>
              </div>
              {tr.detail && <div style={{ fontSize: 11, color: THEME.textTer, fontWeight: 600 }}>{tr.detail}</div>}
            </div>
            <div style={{ textAlign: "center", flex: 1 }}>
              <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>{tr.arrTime || "—"}</div>
              <div style={{ fontSize: 11, color: THEME.textSec, marginTop: 3, lineHeight: 1.3 }}>{tr.to}</div>
            </div>
          </div>
          <ViewDetailsBtn color={THEME.transport} />
        </Card>
      ))}
      {showAdd && (
        <Sheet title="Add Transport" onClose={() => setShowAdd(false)}>
          {/* Day + Type in one row */}
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField label="Day">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>Day 1, Mar 12 ▾</div>
              </FormField>
            </div>
            <div style={{ flex: 1 }}>
              <FormField label="Type">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>✈️ Flight ▾</div>
              </FormField>
            </div>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}><FormField label="From" placeholder="Departure" /></div>
            <div style={{ flex: 1 }}><FormField label="To" placeholder="Arrival" /></div>
          </div>
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}><FormField label="Dep. Time" placeholder="08:00" /></div>
            <div style={{ flex: 1 }}><FormField label="Arr. Time" placeholder="10:30" /></div>
          </div>
          <FormField label="Detail" placeholder="Flight number / reference" />
          {/* Auto-sync note */}
          <div style={{ fontSize: 11, color: THEME.textSec, padding: "4px 0 10px", lineHeight: 1.5 }}>
            🔗 A timeline item will be auto-added to the Daily view for the selected day.
          </div>
          <SaveBtn onClick={() => setShowAdd(false)} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Accommodation Tab ───────────────────────────────────────────────────────
// Changes:
// • Add form: Check-in + Check-out DatePickers (no Day picker)
// • Saving creates one Accommodation per night day + 2 timeline items:
//   "Check-in · HotelName" on check-in day, "Check-out · HotelName" on check-out day
// • Both timeline items share the same linkedId (first night's accommodation.id)
// • Swipe-to-delete removes all accommodation days + both timeline items
const AccommodationTab = ({ trip }) => {
  const [showAdd, setShowAdd] = useState(false);
  const stays = []; let cur = null;
  trip.days.forEach(day => {
    if (!day.accommodation) return;
    if (cur && cur.name === day.accommodation.name) { cur.endDate = day.date; cur.nights++; }
    else { cur = { id: day.accommodation.id, name: day.accommodation.name, address: day.accommodation.address, startDate: day.date, endDate: day.date, nights: 1 }; stays.push(cur); }
  });
  return (
    <div style={{ position: "relative" }}>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Accommodation</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{stays.length} hotel{stays.length !== 1 ? "s" : ""}</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />
      {stays.map((s, i) => (
        <Card key={i}>
          <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
            <div style={{ flex: 1 }}>
              <div style={{ display: "flex", alignItems: "center", gap: 6, fontSize: 16, fontWeight: 700, color: THEME.text }}>
                <span style={{ color: THEME.hotel }}>🛏</span> {s.name}
              </div>
              <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 4 }}>📍 {s.address}</div>
              <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 3 }}>📅 {fmt(s.startDate)} – {fmt(s.endDate)}</div>
            </div>
            <Pill bg={THEME.hotel + "15"} color={THEME.hotel}>{s.nights} night{s.nights > 1 ? "s" : ""}</Pill>
          </div>
          <div style={{ marginTop: 12, display: "flex", gap: 8 }}>
            <div style={{ flex: 1, background: "#f5f5f3", borderRadius: 10, padding: "10px 12px", fontSize: 12, color: "#666", cursor: "pointer", textAlign: "center", fontWeight: 600 }}>📋 Copy Address</div>
            <div style={{ flex: 1, background: "#f5f5f3", borderRadius: 10, padding: "10px 12px", fontSize: 12, color: "#666", cursor: "pointer", textAlign: "center", fontWeight: 600 }}>🗺️ Open Maps</div>
          </div>
          <ViewDetailsBtn color={THEME.hotel} />
        </Card>
      ))}
      {showAdd && (
        <Sheet title="Add Hotel" onClose={() => setShowAdd(false)}>
          <FormField label="Hotel Name" placeholder="e.g. Ramses Hilton" />
          <FormField label="Address" placeholder="Full address" />
          {/* Check-in + Check-out DatePickers side-by-side */}
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField label="Check-in">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>📅 Mar 12, 2026</div>
              </FormField>
            </div>
            <div style={{ flex: 1 }}>
              <FormField label="Check-out">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>📅 Mar 17, 2026</div>
              </FormField>
            </div>
          </div>
          {/* Auto-sync note */}
          <div style={{ fontSize: 11, color: THEME.textSec, padding: "4px 0 10px", lineHeight: 1.5 }}>
            🔗 "Check-in" and "Check-out" items auto-added to Daily timeline. Deleting this card removes both.
          </div>
          <SaveBtn onClick={() => setShowAdd(false)} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Destinations Tab ────────────────────────────────────────────────────────
// Changes:
// • Adding a place auto-creates a TimelineItem in Daily (linkedId = destination.id)
// • Swipe-to-delete on place cards also removes linked Daily item
const DestinationsTab = ({ trip }) => {
  const [showAdd, setShowAdd] = useState(false);
  const total = trip.days.reduce((n, d) => n + d.destinations.length, 0);
  return (
    <div style={{ position: "relative" }}>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Places to Visit</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>{total} destination{total !== 1 ? "s" : ""}</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />
      {trip.days.map((day, di) => day.destinations.length > 0 && (
        <div key={day.date}>
          <SecHead>Day {di + 1} · {fmt(day.date)}</SecHead>
          {day.destinations.map((dest) => {
            const color = typeColor(dest.type);
            return (
              <Card key={dest.id}>
                <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-start" }}>
                  <div style={{ flex: 1 }}>
                    <div style={{ fontSize: 15, fontWeight: 700, color: THEME.text }}>{typeIcon(dest.type)} {dest.name}</div>
                    <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 4 }}>📍 {dest.address}</div>
                    {dest.time && <div style={{ fontSize: 12, color: THEME.textSec, marginTop: 2 }}>🕐 {dest.time}</div>}
                  </div>
                  {dest.ticketPrice && <Pill bg="#FFF8E1" color="#F9A825">{dest.ticketPrice}</Pill>}
                </div>
                {dest.notes && <div style={{ fontSize: 12, color: THEME.textTer, marginTop: 8, fontStyle: "italic" }}>💡 {dest.notes}</div>}
                <ViewDetailsBtn color={color} />
              </Card>
            );
          })}
        </div>
      ))}
      {showAdd && (
        <Sheet title="Add Place" onClose={() => setShowAdd(false)}>
          {/* Day + Type in one row */}
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}>
              <FormField label="Day">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>Day 1, Mar 12 ▾</div>
              </FormField>
            </div>
            <div style={{ flex: 1 }}>
              <FormField label="Type">
                <div style={{ padding: "10px 12px", borderRadius: 10, background: "#f0f0ee", fontSize: 14, color: THEME.primary, fontWeight: 600 }}>🏛️ Attraction ▾</div>
              </FormField>
            </div>
          </div>
          <FormField label="Name" placeholder="e.g. GIZA Pyramids" />
          <FormField label="Address" placeholder="Full address" />
          <div style={{ display: "flex", gap: 10 }}>
            <div style={{ flex: 1 }}><FormField label="Time" placeholder="08:00-12:00" /></div>
            <div style={{ flex: 1 }}><FormField label="Ticket" placeholder="540 EGP" /></div>
          </div>
          <FormField label="Notes" placeholder="Tips..." multiline />
          {/* Auto-sync note */}
          <div style={{ fontSize: 11, color: THEME.textSec, padding: "4px 0 10px", lineHeight: 1.5 }}>
            🔗 A timeline item will be auto-added to the Daily view for the selected day.
          </div>
          <SaveBtn onClick={() => setShowAdd(false)} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Info Tab ────────────────────────────────────────────────────────────────
// Changes from MVP1:
// • Checkboxes removed — info items are pure reference cards (no done/strikethrough state)
// • "View details ›" button on each card (placeholder for MVP3 detail screen)
// • Swipe-to-delete supported
const InfoTab = ({ trip }) => {
  const [items] = useState(trip.info);
  const [showAdd, setShowAdd] = useState(false);
  return (
    <div style={{ position: "relative" }}>
      <div style={{ padding: "10px 20px 6px" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Essential Info</div>
        <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 2 }}>Things to prepare before departure</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />
      {items.map(item => (
        <Card key={item.id}>
          <div style={{ fontSize: 15, fontWeight: 700, color: THEME.text }}>{item.title}</div>
          <div style={{ fontSize: 13, color: THEME.textSec, marginTop: 5, lineHeight: 1.6 }}>{item.details}</div>
          <ViewDetailsBtn color={THEME.primary} />
        </Card>
      ))}
      {showAdd && (
        <Sheet title="Add Info Item" onClose={() => setShowAdd(false)}>
          <FormField label="Title" placeholder="e.g. Travel Insurance" />
          <FormField label="Details" placeholder="Important details..." multiline />
          <SaveBtn onClick={() => setShowAdd(false)} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Day Detail ──────────────────────────────────────────────────────────────
// Changes:
// • Timeline items with linkedId (auto-synced from Transport/Hotels/Places) show
//   a 🔗 badge and CANNOT be deleted here — must delete from the source tab
// • Only manually-added items (linkedId == null) show the delete (✕) button
// • Items are displayed in a List-style scrollable column within each day card
const DayDetail = ({ trip, initialDayIndex, onBack }) => {
  const [dayIdx, setDayIdx] = useState(initialDayIndex);
  const [timelines, setTimelines] = useState(() =>
    trip.days.map(d => ({ items: d.timeline.map(t => ({ ...t, done: false })), dayDone: false }))
  );
  const [showAdd, setShowAdd] = useState(false);
  const scrollRef = useRef(null);
  const cardW = 350;

  useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTo({ left: initialDayIndex * cardW, behavior: "auto" });
  }, []);

  const handleScroll = () => {
    if (scrollRef.current) {
      const idx = Math.round(scrollRef.current.scrollLeft / cardW);
      if (idx !== dayIdx && idx >= 0 && idx < trip.days.length) setDayIdx(idx);
    }
  };

  const toggleDayDone = () => {
    setTimelines(p => {
      const n = [...p];
      const nd = !n[dayIdx].dayDone;
      n[dayIdx] = { ...n[dayIdx], dayDone: nd, items: n[dayIdx].items.map(i => ({ ...i, done: nd })) };
      return n;
    });
  };

  // Only allow deleting items without linkedId
  const deleteItem = (di, id) => {
    setTimelines(p => {
      const n = [...p];
      n[di] = { ...n[di], items: n[di].items.filter(i => i.id !== id) };
      return n;
    });
  };

  const day = trip.days[dayIdx];

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%", position: "relative" }}>
      <BackBtn onClick={onBack} label="Overview" />
      <div style={{ padding: "4px 20px 0" }}>
        <div style={{ fontSize: 24, fontWeight: 800, color: THEME.text }}>Day {dayIdx + 1}</div>
        <div style={{ fontSize: 13, color: THEME.textSec }}>{fmt(day.date)} · {day.city}</div>
      </div>
      <AddBtn onClick={() => setShowAdd(true)} />

      <div ref={scrollRef} onScroll={handleScroll} style={{
        flex: 1, display: "flex", overflowX: "auto", scrollSnapType: "x mandatory",
        padding: "12px 20px 0", WebkitOverflowScrolling: "touch",
        scrollbarWidth: "none", msOverflowStyle: "none",
      }}>
        <style>{`div::-webkit-scrollbar { display: none; }`}</style>
        {trip.days.map((d, di) => {
          const dtl = timelines[di];
          return (
            <div key={d.date} style={{ minWidth: cardW, maxWidth: cardW, scrollSnapAlign: "center" }}>
              <div style={{
                width: 340, minHeight: 400, background: THEME.card, borderRadius: 20,
                boxShadow: "0 2px 16px rgba(0,0,0,0.05)", overflow: "hidden",
                display: "flex", flexDirection: "column",
              }}>
                {/* Day done toggle */}
                <div onClick={() => { if (di === dayIdx) toggleDayDone(); }} style={{
                  display: "flex", alignItems: "center", gap: 10, padding: "12px 14px",
                  background: dtl.dayDone ? THEME.primary + "12" : "#f8f8f6",
                  cursor: di === dayIdx ? "pointer" : "default", borderBottom: "1px solid #f0f0ee",
                }}>
                  <Check checked={dtl.dayDone} onChange={() => { if (di === dayIdx) toggleDayDone(); }} color={THEME.primary} size={20} />
                  <span style={{ fontSize: 13, fontWeight: 600, color: dtl.dayDone ? THEME.primary : THEME.textSec }}>
                    {dtl.dayDone ? "Day completed ✓" : "Mark day as done"}
                  </span>
                  <span style={{ marginLeft: "auto", fontSize: 11, color: THEME.textTer }}>
                    {dtl.items.filter(x => x.done).length}/{dtl.items.length}
                  </span>
                </div>

                {/* Timeline items */}
                <div style={{ flex: 1, overflowY: "auto" }}>
                  {dtl.items.map((item, i) => {
                    const color = typeColor(item.type);
                    const icon = typeIcon(item.type);
                    const isLinked = !!item.linkedId; // auto-synced from another tab

                    return (
                      <div key={item.id} style={{
                        display: "flex", opacity: item.done ? 0.4 : 1, transition: "opacity 0.3s",
                        borderBottom: i < dtl.items.length - 1 ? "1px solid #f0f0ee" : "none",
                      }}>
                        {/* Color bar */}
                        <div style={{ width: 4, background: color, flexShrink: 0 }} />
                        <div style={{ flex: 1, padding: "11px 10px 11px 10px", display: "flex", gap: 8, alignItems: "flex-start" }}>
                          <div style={{ flex: 1, minWidth: 0 }}>
                            {/* Time + icon + linked badge */}
                            <div style={{ display: "flex", alignItems: "center", gap: 5, marginBottom: 3 }}>
                              <span style={{ fontSize: 10, fontWeight: 700, color, background: color + "14", padding: "2px 7px", borderRadius: 5 }}>{item.time}</span>
                              <span style={{ fontSize: 12 }}>{icon}</span>
                              {/* 🔗 badge: linked items cannot be deleted here */}
                              {isLinked && (
                                <span style={{ fontSize: 9, color: THEME.textTer, background: "#f0f0ee", padding: "1px 5px", borderRadius: 4, fontWeight: 600 }}>🔗 synced</span>
                              )}
                            </div>
                            {/* Title */}
                            <div style={{ fontSize: 14, fontWeight: 600, color: THEME.text, lineHeight: 1.3, textDecoration: item.done ? "line-through" : "none" }}>{item.title}</div>
                            {/* Note */}
                            {item.note && <div style={{ fontSize: 11, color: THEME.textSec, marginTop: 2, lineHeight: 1.4 }}>{item.note}</div>}
                            {/* Synced items: note that deletion must happen from source tab */}
                            {isLinked && (
                              <div style={{ fontSize: 10, color: THEME.textTer, marginTop: 4, fontStyle: "italic" }}>
                                Delete from Transport / Hotels / Places tab
                              </div>
                            )}
                          </div>
                          {/* Delete button — only for manually-added items (linkedId == null) */}
                          {!isLinked && (
                            <div onClick={() => { if (di === dayIdx) deleteItem(di, item.id); }}
                              style={{ width: 24, height: 24, borderRadius: 6, background: "#FF3B3010", display: "flex", alignItems: "center", justifyContent: "center", cursor: di === dayIdx ? "pointer" : "default", flexShrink: 0, marginTop: 2 }}>
                              <span style={{ fontSize: 12, color: "#FF3B30", fontWeight: 700 }}>✕</span>
                            </div>
                          )}
                        </div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Day dots */}
      <div style={{ display: "flex", justifyContent: "center", gap: 5, padding: "10px 0 4px" }}>
        {trip.days.map((_, i) => (
          <div key={i} style={{
            width: dayIdx === i ? 20 : 6, height: 6, borderRadius: 3,
            background: dayIdx === i ? THEME.primary : "#ddd",
            transition: "all 0.3s", cursor: "pointer",
          }} onClick={() => {
            if (scrollRef.current) scrollRef.current.scrollTo({ left: i * cardW, behavior: "smooth" });
          }} />
        ))}
      </div>

      {showAdd && (
        <Sheet title="Add Timeline Item" onClose={() => setShowAdd(false)}>
          <FormField label="Time" placeholder="08:00" />
          <FormField label="Title" placeholder="What to do" />
          <FormField label="Type" placeholder="flight / hotel / attraction / restaurant / other" />
          <FormField label="Notes" placeholder="Additional details..." multiline />
          <div style={{ fontSize: 11, color: THEME.textSec, padding: "4px 0 10px", lineHeight: 1.5 }}>
            ✏️ Manually added items can be deleted from this view. Auto-synced items (🔗 synced) must be deleted from their source tab.
          </div>
          <SaveBtn onClick={() => setShowAdd(false)} />
        </Sheet>
      )}
    </div>
  );
};

// ─── Main App ────────────────────────────────────────────────────────────────
export default function App() {
  const [screen, setScreen] = useState("home");
  const [trip, setTrip] = useState(null);
  const [tripTab, setTripTab] = useState("overview");
  const [dayIdx, setDayIdx] = useState(null);
  const [mainTab, setMainTab] = useState("trips");

  const openTrip = (t) => { setTrip(t); setScreen("trip"); setTripTab("overview"); setDayIdx(null); };
  const goHome = () => { setScreen("home"); setTrip(null); setDayIdx(null); setMainTab("trips"); };

  const inTrip = screen === "trip";
  const time = new Date().toLocaleTimeString("en-US", { hour: "2-digit", minute: "2-digit", hour12: false });

  return (
    <div style={{
      width: 390, height: 844, borderRadius: 44, overflow: "hidden",
      background: THEME.bg, fontFamily: "'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif",
      position: "relative", display: "flex", flexDirection: "column",
      boxShadow: "0 25px 80px rgba(0,0,0,0.2), 0 0 0 1px rgba(0,0,0,0.08)",
      margin: "20px auto",
    }}>
      {/* Status bar */}
      <div style={{ height: 54, display: "flex", alignItems: "flex-end", justifyContent: "center", padding: "0 28px 8px" }}>
        <span style={{ fontSize: 14, fontWeight: 600, color: THEME.text }}>{time}</span>
        <span style={{ flex: 1 }} />
        <span style={{ fontSize: 11 }}>📶 🔋</span>
      </div>

      {/* Content */}
      <div style={{ flex: 1, overflowY: "auto", overflowX: "hidden", WebkitOverflowScrolling: "touch", position: "relative" }}>
        {screen === "home" && mainTab === "trips"    && <TripList onSelect={openTrip} />}
        {screen === "home" && mainTab === "todo"     && <TodoList />}
        {screen === "home" && mainTab === "settings" && <Settings />}

        {inTrip && dayIdx !== null && <DayDetail trip={trip} initialDayIndex={dayIdx} onBack={() => setDayIdx(null)} />}
        {inTrip && dayIdx === null && (
          <>
            <BackBtn onClick={goHome} label="My Trips" />
            {tripTab === "overview"       && <OverviewTab trip={trip} onDay={i => setDayIdx(i)} />}
            {tripTab === "transport"      && <TransportTab trip={trip} />}
            {tripTab === "accommodation"  && <AccommodationTab trip={trip} />}
            {tripTab === "destinations"   && <DestinationsTab trip={trip} />}
            {tripTab === "info"           && <InfoTab trip={trip} />}
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
