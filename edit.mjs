const bag = new Map()
globalThis.localStorage = {
  getItem(key) { return bag.has(key) ? bag.get(key) : null },
  setItem(key, value) { bag.set(key, String(value)) },
  removeItem(key) { bag.delete(key) },
  clear() { bag.clear() },
  key(index) { return [...bag.keys()][index] ?? null },
  get length() { return bag.size },
}
globalThis.window = { dispatchEvent() {}, clearTimeout, setTimeout }

const root = "/Users/furkanturkkan/ortaokul-gunluk/src"
const { tally } = await import(`${root}/lib/points.js`)
const { scoreTrials } = await import(`${root}/lib/trial.js`)
const { SCHOOL_DAYS, formatISO } = await import(`${root}/lib/calendar.js`)
const { grade5 } = await import(`${root}/data/grade5.js`)
const { grade6 } = await import(`${root}/data/grade6.js`)
const { grade7 } = await import(`${root}/data/grade7.js`)
const { grade8 } = await import(`${root}/data/grade8.js`)
const tracks = { 5: grade5, 6: grade6, 7: grade7, 8: grade8 }

function hashPassword(password) {
  let hash = 2166136261
  const text = `sira:${password}`
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i)
    hash = Math.imul(hash, 16777619)
  }
  return (hash >>> 0).toString(36)
}

function dueDay() {
  const today = formatISO(new Date())
  let due = ""
  for (const day of SCHOOL_DAYS) {
    if (day.iso <= today) due = day.iso
    else break
  }
  return due || today
}

const raw = await new Promise((resolve) => {
  let body = ""
  process.stdin.setEncoding("utf8")
  process.stdin.on("data", (chunk) => { body += chunk })
  process.stdin.on("end", () => resolve(body))
})

const input = JSON.parse(raw || "{}")
const store = input.store || {}
const account = (store.accounts || []).find((item) => item.id === input.id)
if (!account) {
  process.stderr.write("Hesap bulunamadı.")
  process.exit(1)
}
const streak = Number(input.streak)
const points = Number(input.points)
if (!Number.isInteger(streak) || streak < 0 || !Number.isInteger(points) || points < 0) {
  process.stderr.write("Seri ve puan sıfır ya da daha büyük bir sayı olsun.")
  process.exit(1)
}
const password = String(input.password || "")
if (password && password.length < 4) {
  process.stderr.write("Şifre en az dört karakter olsun.")
  process.exit(1)
}

function cleanEmail(value) {
  return String(value || "").trim().toLowerCase()
}

function isEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)
}

const typedEmail = cleanEmail(input.email)
const currentEmail = cleanEmail(account.email || (String(account.name).includes("@") ? account.name : ""))
if (typedEmail && !isEmail(typedEmail)) {
  process.stderr.write("Geçerli bir e-posta yaz.")
  process.exit(1)
}
if (typedEmail && typedEmail !== currentEmail) {
  const taken = (store.accounts || []).some((item) => {
    if (!item || item.id === account.id) return false
    return cleanEmail(item.email) === typedEmail || cleanEmail(item.name) === typedEmail
  })
  if (taken) {
    process.stderr.write("Bu e-posta başka hesapta var.")
    process.exit(1)
  }
}

const answers = store.answers && typeof store.answers === "object" ? store.answers : {}
const trials = store.trials && typeof store.trials === "object" ? store.trials : {}
localStorage.setItem(`sira-trials-${account.id}`, JSON.stringify(trials[account.id] || {}))
const lesson = tally(answers[account.id] || {}).total
const trialPoints = tracks[account.grade] ? scoreTrials(account.id, account.grade, tracks[account.grade]) : 0
const now = Date.now()
const next = {
  ...account,
  pointAdjust: points - (lesson + streak + trialPoints),
  pointRev: now,
}
if (password) {
  const hash = hashPassword(password)
  next.passwordHash = hash
  next.passwordHashes = [hash]
  next.passwordRev = now
}
if (typedEmail && typedEmail !== currentEmail) {
  next.email = typedEmail
  next.emailRev = now
  if (String(account.name).includes("@")) next.name = typedEmail
}

process.stdout.write(JSON.stringify({
  accounts: [next],
  streaks: { [account.id]: { last: dueDay(), streak, setAt: now } },
  answers: {},
  threads: [],
  trials: {},
}))
