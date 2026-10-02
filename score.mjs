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
const { grade5 } = await import(`${root}/data/grade5.js`)
const { grade6 } = await import(`${root}/data/grade6.js`)
const { grade7 } = await import(`${root}/data/grade7.js`)
const { grade8 } = await import(`${root}/data/grade8.js`)

const tracks = { 5: grade5, 6: grade6, 7: grade7, 8: grade8 }
const raw = await new Promise((resolve) => {
  let body = ""
  process.stdin.setEncoding("utf8")
  process.stdin.on("data", (chunk) => { body += chunk })
  process.stdin.on("end", () => resolve(body))
})
const data = JSON.parse(raw || "{}")
const answers = data.answers && typeof data.answers === "object" ? data.answers : {}
const trials = data.trials && typeof data.trials === "object" ? data.trials : {}
const streaks = data.streaks && typeof data.streaks === "object" ? data.streaks : {}
const scores = {}
for (const account of data.accounts || []) {
  if (!account?.id) continue
  const id = account.id
  localStorage.setItem(`sira-trials-${id}`, JSON.stringify(trials[id] || {}))
  const lesson = tally(answers[id] || {}).total
  const trialPoints = tracks[account.grade] ? scoreTrials(id, account.grade, tracks[account.grade]) : 0
  const streak = Number(streaks[id]?.streak) || 0
  const adjust = Number(account.pointAdjust) || 0
  scores[id] = lesson + streak + trialPoints + adjust
}
process.stdout.write(JSON.stringify(scores))
