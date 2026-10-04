/*
#########################################################################
##   This file is controlled by Puppet - changes will be overwritten   ##
#########################################################################
*/

'use strict';

const BOARD_POLL_MS = 60000;   // background refresh is 30 min; this just re-reads
const STATE_POLL_MS = 2000;    // screen state and revert requests
const REFRESH_SETTLE_MS = 2500;

const el = (id) => document.getElementById(id);

const dom = {
    topbar: el('topbar'),
    todayDate: el('today-date'),
    refresh: el('refresh'),
    banner: el('banner'),
    board: el('board'),
    days: el('days'),
    money: el('money'),
    moneyBody: el('money-body'),
    moneyEmpty: el('money-empty'),
    frames: { home: el('frame-home'), graphs: el('frame-graphs') },
    frameError: el('frame-error'),
    frameErrorDetail: el('frame-error-detail'),
    frameRetry: el('frame-retry'),
    status: el('status'),
    statusUpdated: el('status-updated'),
    statusWifi: el('status-wifi'),
    statusLoad: el('status-load'),
    statusNext: el('status-next'),
    statusFlag: el('status-flag'),
    tabs: Array.from(document.querySelectorAll('.tab')),
    dayOverlay: el('day-overlay'),
    dayTitle: el('day-title'),
    dayWeather: el('day-weather'),
    dayList: el('day-list'),
    dayClose: el('day-close'),
    weather: el('weather'),
    weatherLine: el('weather-line'),
    wakeShield: el('wake-shield'),
};

const app = {
    payload: null,
    payloadText: null,
    moneyText: null,
    tabUrls: { home: null, graphs: null },
    // Loaded frames stay alive for fast tab switching.
    framesLoaded: { home: false, graphs: false },
    activeTab: 'board',
    screenOn: true,
};

async function getJson(path) {
    const resp = await fetch(path, { cache: 'no-store' });
    if (!resp.ok) {
        throw new Error(`${path} -> ${resp.status}`);
    }
    return resp.json();
}

async function postJson(path, body) {
    const resp = await fetch(path, {
        method: 'POST',
        cache: 'no-store',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body || {}),
    });
    return resp;
}

function show(node, visible) {
    node.hidden = !visible;
}

function renderBanner(health) {
    const messages = health.messages || [];
    if (!messages.length) {
        dom.banner.hidden = true;
        dom.banner.textContent = '';
        return;
    }
    dom.banner.hidden = false;
    if (messages.length === 1) {
        dom.banner.textContent = messages[0];
        return;
    }
    const list = document.createElement('ul');
    for (const message of messages) {
        const item = document.createElement('li');
        item.textContent = message;
        list.appendChild(item);
    }
    dom.banner.replaceChildren(list);
}

function localIso(date) {
    const pad = (n) => String(n).padStart(2, '0');
    return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`;
}

function make(tag, className, text) {
    const node = document.createElement(tag);
    if (className) {
        node.className = className;
    }
    if (text !== undefined && text !== null) {
        node.textContent = text;
    }
    return node;
}

const WEATHER_ICONS = {
    'Clear': '\u2600', 'Sunny spells': '\u2600', 'Cloudy': '\u2601',
    'Fog': '\u2248', 'Drizzle': '\u2602', 'Rain': '\u2602', 'Showers': '\u2602',
    'Snow': '\u2744', 'Storms': '\u26a1',
};

function weatherBadge(weather) {
    const badge = make('span', 'day-wx');
    badge.append(make('span', 'day-wx-icon', WEATHER_ICONS[weather.description] || '\u2601'),
        weather.temp_max === null ? '--\u00b0' : `${Math.round(weather.temp_max)}\u00b0`);
    return badge;
}

const BUSY_START = 7 * 60;
const BUSY_SPAN = 15 * 60;

function minutes(hhmm) {
    return Number(hhmm.slice(0, 2)) * 60 + Number(hhmm.slice(3, 5));
}

function busyBar(day) {
    const track = make('span', 'busy');
    for (const event of day.events) {
        if (!event.start_time) {
            track.classList.add('is-allday');
            continue;
        }
        const from = Math.max(0, minutes(event.start_time) - BUSY_START);
        const endTime = event.end_time && event.end_time > event.start_time
            ? event.end_time : event.start_time;
        const to = Math.min(BUSY_SPAN, Math.max(from + 20, minutes(endTime) - BUSY_START));
        if (from >= BUSY_SPAN) {
            continue;
        }
        const block = make('span', 'busy-block');
        block.style.left = `${(from / BUSY_SPAN) * 100}%`;
        block.style.width = `${((to - from) / BUSY_SPAN) * 100}%`;
        track.appendChild(block);
    }
    return track;
}

function isDayOff(day) {
    return day.is_weekend || Boolean(day.bank_holiday);
}

function buildDayRow(day, todayIso) {
    const row = make('button', 'day');
    row.type = 'button';
    row.dataset.date = day.date;
    row.classList.toggle('is-week-start', day.is_week_start);
    row.classList.toggle('is-day-off', isDayOff(day));
    row.classList.toggle('is-today', day.date === todayIso);

    const label = make('span', 'day-label', day.weekday_text);
    label.prepend(make('b', null, day.day_number));

    const lane = make('span', 'day-lane');
    const span = day.events.find((event) => event.multi_day);
    if (span) {
        lane.classList.add('is-on', `is-${span.continues}`);
    }

    const items = make('span', 'day-items');
    if (day.bank_holiday) {
        items.appendChild(make('span', 'day-holiday', day.bank_holiday));
    }
    for (const event of day.events) {
        const item = make('span', 'day-item');
        if (event.multi_day && event.continues !== 'first') {
            item.classList.add('is-continuing');
            item.textContent = event.title;
        } else if (event.multi_day || event.all_day) {
            item.classList.add('is-allday');
            item.textContent = event.multi_day ? `${event.title} \u2192` : event.title;
        } else {
            item.append(make('time', null, event.start_time), ` ${event.title}`);
        }
        items.appendChild(item);
    }
    if (!day.events.length && !day.bank_holiday) {
        items.appendChild(make('span', 'day-free', 'free'));
    }

    const side = make('span', 'day-side');
    if (day.weather) {
        side.appendChild(weatherBadge(day.weather));
    }
    side.appendChild(busyBar(day));

    row.append(label, lane, items, side);
    return row;
}

function isFoldable(day, todayIso) {
    return !day.events.length && !isDayOff(day) && day.date !== todayIso;
}

function buildFreeBand(run) {
    const first = run[0];
    const last = run[run.length - 1];
    const band = make('div', 'free-band');
    band.classList.toggle('is-week-start', first.is_week_start);
    if (run.length === 1) {
        band.append(make('b', null, 'Free'), ` ${first.weekday_text} ${first.day_number}`);
    } else {
        band.append(make('b', null, `Free ${run.length} days`),
            ` ${first.weekday_text} ${first.day_number} to ${last.weekday_text} ${last.day_number}`);
    }
    return band;
}

function renderDays(payload) {
    const todayIso = localIso(new Date());
    const days = payload.days.filter((day) => day.date >= todayIso);
    const fragment = document.createDocumentFragment();
    for (let i = 0; i < days.length; i++) {
        let j = i;
        while (j < days.length && isFoldable(days[j], todayIso)
               && (j === i || !days[j].is_week_start)) {
            j++;
        }
        if (j > i) {
            fragment.appendChild(buildFreeBand(days.slice(i, j)));
            i = j - 1;
            continue;
        }
        fragment.appendChild(buildDayRow(days[i], todayIso));
    }
    dom.days.replaceChildren(fragment);
}

const WEATHER_SWITCH_HOUR = 15;

function weatherDay(payload) {
    const todayIso = localIso(new Date());
    const days = payload.days.filter((day) => day.date >= todayIso);
    const index = new Date().getHours() >= WEATHER_SWITCH_HOUR ? 1 : 0;
    return days[index] && days[index].weather ? { day: days[index], tomorrow: index === 1 } : null;
}

function renderWeather(payload) {
    const pick = weatherDay(payload);
    dom.weather.disabled = !pick;
    if (!pick) {
        dom.weatherLine.textContent = 'Weather unavailable';
        return;
    }
    dom.weatherLine.textContent =
        `${pick.tomorrow ? 'Tomorrow' : 'Today'}  \u00b7  ${weatherDetail(pick.day.weather)}`;
    dom.weather.dataset.date = pick.day.date;
}

function renderDate() {
    dom.todayDate.textContent = new Date().toLocaleDateString('en-GB',
        { weekday: 'long', day: 'numeric', month: 'long' });
}

function renderStatus(payload) {
    const status = payload.status;
    dom.statusUpdated.textContent = `Updated ${status.updated_text}`;
    dom.statusWifi.textContent = status.wifi_percent === null
        ? 'WiFi --%'
        : `WiFi ${status.wifi_percent}%`;
    dom.statusLoad.textContent = status.load_average === null
        ? 'Load --'
        : `Load ${status.load_average}`;
    dom.statusNext.textContent = `Refresh ${status.next_refresh_text}`;

    const health = payload.health;
    const bad = !health.ok;
    dom.statusFlag.textContent = health.stale
        ? 'STALE'
        : (bad ? 'DEGRADED' : 'OK');
    dom.statusFlag.classList.toggle('is-stale', health.stale);
    dom.statusFlag.classList.toggle('is-bad', bad && !health.stale);
}

function render(payload) {
    app.payload = payload;
    renderBanner(payload.health);
    renderDate();
    renderDays(payload);
    renderWeather(payload);
    renderStatus(payload);
}

async function loadBoard() {
    try {
        const resp = await fetch('/api/board', { cache: 'no-store' });
        if (!resp.ok) {
            throw new Error(`/api/board -> ${resp.status}`);
        }
        const text = await resp.text();
        if (app.payload && text === app.payloadText) {
            renderBanner(app.payload.health);
            renderWeather(app.payload);
            return;
        }
        app.payloadText = text;
        render(JSON.parse(text));
    } catch (err) {
        console.warn('board load failed', err);
        dom.banner.hidden = false;
        dom.banner.textContent = 'Board service not responding';
    }
}

async function manualRefresh() {
    dom.refresh.classList.add('is-busy');
    dom.refresh.disabled = true;
    try {
        const resp = await postJson('/api/refresh');
        if (resp.status === 429) {
            dom.banner.hidden = false;
            dom.banner.textContent = 'Just refreshed - try again in a moment';
        }
        // The refresh runs asynchronously on the server, so wait before re-reading
        // or the same payload comes back.
        await new Promise((resolve) => setTimeout(resolve, REFRESH_SETTLE_MS));
        await loadBoard();
    } catch (err) {
        console.warn('refresh failed', err);
    } finally {
        dom.refresh.classList.remove('is-busy');
        dom.refresh.disabled = false;
    }
}

function weatherDetail(weather) {
    const lo = weather.temp_min === null ? '--' : Math.round(weather.temp_min);
    const hi = weather.temp_max === null ? '--' : Math.round(weather.temp_max);
    const bits = [weather.description, `${lo}\u00b0 / ${hi}\u00b0`];
    if (weather.precip_chance !== null) {
        bits.push(`${weather.precip_chance}% rain`);
    }
    if (weather.uv_text) {
        bits.push(weather.uv_text);
    }
    return bits.join('  \u00b7  ');
}

function openDay(date) {
    const day = app.payload && app.payload.days.find((d) => d.date === date);
    if (!day) {
        return;
    }
    const long = new Date(`${day.date}T12:00:00`).toLocaleDateString('en-GB',
        { weekday: 'long', day: 'numeric', month: 'long' });
    dom.dayTitle.textContent = day.bank_holiday ? `${long} \u00b7 ${day.bank_holiday}` : long;
    if (day.weather) {
        dom.dayWeather.textContent = weatherDetail(day.weather);
    }
    show(dom.dayWeather, Boolean(day.weather));

    const fragment = document.createDocumentFragment();
    for (const event of day.events) {
        const item = make('li');
        item.append(make('span', 'day-list-time', event.time_text),
            make('span', 'day-list-title', event.title));
        if (event.location) {
            item.appendChild(make('span', 'day-list-where', event.location));
        }
        fragment.appendChild(item);
    }
    if (!day.events.length) {
        fragment.appendChild(make('li', 'day-list-empty', 'Nothing planned'));
    }
    dom.dayList.replaceChildren(fragment);
    show(dom.dayOverlay, true);
    dom.dayClose.focus();
}

function closeOverlays() {
    show(dom.dayOverlay, false);
}

function setActiveTab(name) {
    app.activeTab = name;
    for (const tab of dom.tabs) {
        const active = tab.dataset.tab === name;
        tab.classList.toggle('is-active', active);
        if (active) {
            tab.setAttribute('aria-current', 'page');
        } else {
            tab.removeAttribute('aria-current');
        }
    }
    const onBoard = name === 'board';
    show(dom.topbar, onBoard);
    show(dom.weather, onBoard);
    show(dom.status, onBoard);
    // Report the active tab, so the device knows whether a revert applies.
    postJson('/api/page', { page: name }).catch(() => {});
}

function hideAllFrames() {
    for (const frame of Object.values(dom.frames)) {
        frame.classList.remove('is-front');
    }
}

function showBoard() {
    closeOverlays();
    setActiveTab('board');
    show(dom.money, false);
    show(dom.board, true);
    dom.board.scrollTop = 0;
    hideAllFrames();
    show(dom.frameError, false);
}

function loadFrame(name) {
    const url = app.tabUrls[name];
    const frame = dom.frames[name];
    if (!url || !frame || app.framesLoaded[name]) {
        return;
    }
    app.framesLoaded[name] = true;
    frame.src = url;
}

function preloadFrames() {
    loadFrame('home');
    loadFrame('graphs');
}

function showEmbedded(name) {
    const url = app.tabUrls[name];
    const tab = dom.tabs.find((candidate) => candidate.dataset.tab === name);
    const alreadyLoaded = app.framesLoaded[name];
    closeOverlays();
    setActiveTab(name);
    show(dom.board, false);
    show(dom.money, false);
    if (!url) {
        hideAllFrames();
        dom.frameErrorDetail.textContent = 'No address configured for this tab.';
        show(dom.frameError, true);
        return;
    }
    show(dom.frameError, false);
    for (const [otherName, otherFrame] of Object.entries(dom.frames)) {
        otherFrame.classList.toggle('is-front', otherName === name);
    }
    if (!alreadyLoaded && tab) {
        tab.classList.add('is-loading');
    }
    loadFrame(name);
}

function isoDiff(from, to) {
    return Math.round((new Date(`${to}T12:00:00`) - new Date(`${from}T12:00:00`)) / 86400000);
}

function clamp01(value) {
    return Math.max(0, Math.min(1, value));
}

function money(value, pence) {
    const digits = pence ? 2 : 0;
    const text = Math.abs(value).toLocaleString('en-GB',
        { minimumFractionDigits: digits, maximumFractionDigits: digits });
    return `${value < 0 ? '-' : ''}\u00a3${text}`;
}

function shortDate(iso) {
    return new Date(`${iso}T12:00:00`).toLocaleDateString('en-GB',
        { weekday: 'short', day: 'numeric', month: 'short' });
}

function budgetClock(summary) {
    const today = localIso(new Date());
    const asOf = summary.generated_at.slice(0, 10);
    const total = isoDiff(summary.budget_start, summary.budget_end);
    return {
        total,
        day: Math.min(total, isoDiff(summary.budget_start, today) + 1),
        asOf,
        elapsedToday: clamp01(isoDiff(summary.budget_start, today) / total),
        elapsedAsOf: clamp01(isoDiff(summary.budget_start, asOf) / total),
    };
}

function pace(envelope, clock) {
    if (envelope.balance < 0) {
        return 'over';
    }
    if (envelope.frequency !== 'Monthly' || !(envelope.monthly_budget > 0)) {
        return 'none';
    }
    const gap = envelope.pct_remaining - (1 - clock.elapsedAsOf);
    if (gap >= -0.05) {
        return 'good';
    }
    return gap >= -0.2 ? 'watch' : 'behind';
}

const PACE_ORDER = { over: 0, behind: 1, watch: 2, good: 3, none: 4 };
const PACE_TEXT = { over: 'Overspent', behind: 'Behind', watch: 'Watch', good: 'On track', none: '' };

function buildMonthHeader(summary, clock) {
    const header = make('div', 'month');
    const line = make('p', 'month-line');
    line.append(make('strong', null, `Budget month: day ${clock.day} of ${clock.total}`),
        ` \u00b7 refills ${shortDate(summary.budget_end)}`);

    const bar = make('div', 'month-bar');
    const fill = make('div', 'month-fill');
    fill.style.width = `${clock.elapsedToday * 100}%`;
    const asOf = make('div', 'month-asof');
    asOf.style.left = `${clock.elapsedAsOf * 100}%`;
    bar.append(fill, asOf);

    const legend = make('p', 'month-legend');
    const ago = summary.age_days === 0 ? 'today'
        : (summary.age_days === 1 ? 'yesterday' : `${summary.age_days} days ago`);
    legend.append(make('span', 'key-today', 'today'),
        make('span', 'key-asof', `balances from ${shortDate(clock.asOf)}`),
        make('span', summary.stale ? 'is-stale' : null, `reconciled ${ago}`));
    header.append(line, bar, legend);
    return header;
}

function buildTransactions(envelope) {
    if (!envelope.transactions.length) {
        return make('p', 'tx-none', 'No transactions since the budget started');
    }
    const table = make('table', 'tx');
    for (const t of envelope.transactions) {
        const row = make('tr');
        row.append(make('td', 'tx-date', shortDate(t.date)),
            make('td', 'tx-amount', money(t.amount, true)),
            make('td', 'tx-payee', t.payee), make('td', 'tx-note', t.note));
        table.appendChild(row);
    }
    return table;
}

function buildEnvelope(envelope, state, clock) {
    const item = make('details', `env is-${state}`);
    const summary = make('summary');
    const top = make('div', 'env-top');
    const left = make('span', 'env-left', money(envelope.balance));
    if (envelope.monthly_budget > 0) {
        left.appendChild(make('small', null, ` of ${money(envelope.monthly_budget)}`));
    }
    top.append(make('span', 'env-name', envelope.name), left);
    summary.appendChild(top);

    if (state !== 'none') {
        const meter = make('div', 'env-meter');
        const fill = make('div', 'env-fill');
        fill.style.width = `${envelope.pct_remaining * 100}%`;
        const should = make('div', 'env-should');
        should.style.left = `${(1 - clock.elapsedAsOf) * 100}%`;
        meter.append(fill, should);
        summary.appendChild(meter);
    }

    const foot = make('div', 'env-foot');
    foot.append(make('span', 'env-tag', PACE_TEXT[state]),
        make('span', null, envelope.transactions.length
            ? `${money(envelope.total_spend)} spent \u00b7 tap for detail`
            : 'nothing spent yet'));
    summary.appendChild(foot);
    item.append(summary, buildTransactions(envelope));
    return item;
}

function renderMoney(summary) {
    const clock = budgetClock(summary);
    const fragment = document.createDocumentFragment();
    fragment.appendChild(buildMonthHeader(summary, clock));

    fragment.appendChild(make('h2', 'money-heading', 'This month'));
    const key = summary.key
        .map((envelope) => ({ envelope, state: pace(envelope, clock) }))
        .sort((a, b) => PACE_ORDER[a.state] - PACE_ORDER[b.state]);
    for (const { envelope, state } of key) {
        fragment.appendChild(buildEnvelope(envelope, state, clock));
    }

    if (summary.longer_term.length) {
        fragment.appendChild(make('h2', 'money-heading', 'Longer term'));
        const tiles = make('div', 'tiles');
        for (const envelope of summary.longer_term) {
            const tile = make('div', 'tile');
            tile.append(make('b', null, money(envelope.balance)),
                make('span', null, envelope.name));
            tiles.appendChild(tile);
        }
        fragment.appendChild(tiles);
    }
    dom.moneyBody.replaceChildren(fragment);
}

async function loadMoney() {
    try {
        const resp = await fetch('/api/envelopes', { cache: 'no-store' });
        if (resp.status === 503) {
            app.moneyText = null;
            dom.moneyBody.replaceChildren();
            show(dom.moneyEmpty, true);
            return;
        }
        if (!resp.ok) {
            throw new Error(`/api/envelopes -> ${resp.status}`);
        }
        const text = await resp.text();
        show(dom.moneyEmpty, false);
        if (text === app.moneyText) {
            return;
        }
        app.moneyText = text;
        renderMoney(JSON.parse(text));
    } catch (err) {
        console.warn('envelope load failed', err);
    }
}

function showMoney() {
    closeOverlays();
    setActiveTab('money');
    show(dom.board, false);
    hideAllFrames();
    show(dom.frameError, false);
    show(dom.money, true);
    dom.money.scrollTop = 0;
    loadMoney();
}

function reportFrameProblem(name, detail) {
    dom.frames[name].classList.remove('is-front');
    app.framesLoaded[name] = false;
    if (app.activeTab !== name) {
        return;
    }
    dom.frameErrorDetail.textContent = detail;
    show(dom.frameError, true);
}

async function screenOff() {
    closeOverlays();
    showBoard();
    try {
        const resp = await postJson('/api/screen', { on: false });
        if (resp.status === 501) {
            dom.banner.hidden = false;
            dom.banner.textContent = 'Screen control unavailable on this host';
        }
    } catch (err) {
        console.warn('screen off failed', err);
    }
}

async function pollState() {
    let state;
    try {
        state = await getJson('/api/state');
    } catch (err) {
        return;
    }

    if (state.screen_on !== app.screenOn) {
        app.screenOn = state.screen_on;
        show(dom.wakeShield, !state.screen_on);
    }

    if (state.revert_to_board) {
        if (app.activeTab !== 'board') {
            showBoard();
        } else {
            setActiveTab('board');
        }
    }
}

function wire() {
    dom.refresh.addEventListener('click', manualRefresh);

    dom.days.addEventListener('click', (evt) => {
        const row = evt.target.closest('.day');
        if (row) {
            openDay(row.dataset.date);
        }
    });

    dom.dayClose.addEventListener('click', closeOverlays);
    dom.weather.addEventListener('click', () => openDay(dom.weather.dataset.date));
    dom.dayOverlay.addEventListener('click', (evt) => {
        if (evt.target === dom.dayOverlay) {
            closeOverlays();
        }
    });
    document.addEventListener('keydown', (evt) => {
        if (evt.key === 'Escape') {
            closeOverlays();
        }
    });

    for (const tab of dom.tabs) {
        tab.addEventListener('click', () => {
            const name = tab.dataset.tab;
            if (name === 'board') {
                showBoard();
            } else if (name === 'money') {
                showMoney();
            } else if (name === 'screenoff') {
                screenOff();
            } else {
                showEmbedded(name);
            }
        });
    }

    dom.frameRetry.addEventListener('click', () => {
        const name = app.activeTab;
        const frame = dom.frames[name];
        if (name === 'board' || !frame) {
            return;
        }

        show(dom.frameError, false);
        frame.classList.add('is-front');
        frame.src = app.tabUrls[name];
    });

    for (const [name, frame] of Object.entries(dom.frames)) {
        frame.addEventListener('error', () => {
            reportFrameProblem(name, 'The local proxy did not answer.');
        });
        frame.addEventListener('load', () => {
            for (const tab of dom.tabs) {
                tab.classList.remove('is-loading');
            }
        });
    }

    dom.wakeShield.addEventListener('pointerdown', (evt) => {
        evt.preventDefault();
        evt.stopPropagation();
        postJson('/api/screen', { on: true }).catch(() => {});
        showBoard();
    });
}

async function loadUi() {
    try {
        const ui = await getJson('/api/ui');
        app.tabUrls.home = ui.home_url || null;
        app.tabUrls.graphs = ui.graphs_url || null;
    } catch (err) {
        console.warn('ui config load failed', err);
    }
}

async function start() {
    wire();
    await loadUi();
    preloadFrames();
    await loadBoard();
    loadMoney();
    setActiveTab('board');
    setInterval(() => {
        loadBoard();
        loadMoney();
    }, BOARD_POLL_MS);
    setInterval(pollState, STATE_POLL_MS);
}

start();
