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
    heroTitle: el('hero-title'),
    heroWhen: el('hero-when'),
    heroWhere: el('hero-where'),
    sections: el('sections'),
    empty: el('empty'),
    frames: { home: el('frame-home'), graphs: el('frame-graphs') },
    frameError: el('frame-error'),
    frameErrorDetail: el('frame-error-detail'),
    frameRetry: el('frame-retry'),
    weather: el('weather'),
    weatherLine: el('weather-line'),
    status: el('status'),
    statusUpdated: el('status-updated'),
    statusWifi: el('status-wifi'),
    statusLoad: el('status-load'),
    statusNext: el('status-next'),
    statusFlag: el('status-flag'),
    tabs: Array.from(document.querySelectorAll('.tab')),
    eventOverlay: el('event-overlay'),
    eventWhen: el('event-when'),
    eventTitle: el('event-title'),
    eventWhere: el('event-where'),
    eventRange: el('event-range'),
    eventClose: el('event-close'),
    forecast: el('forecast'),
    forecastList: el('forecast-list'),
    forecastClose: el('forecast-close'),
    wakeShield: el('wake-shield'),
};

const app = {
    payload: null,
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

function renderHero(payload) {
    const today = payload.today;
    dom.todayDate.textContent = today.date_text;

    const next = today.next_event;
    if (!next) {
        dom.heroTitle.textContent = today.event_count
            ? 'Nothing else today'
            : 'Clear day';
        dom.heroWhen.textContent = '';
        show(dom.heroWhere, false);
        return;
    }
    dom.heroTitle.textContent = next.title;
    dom.heroWhen.textContent = next.time_text || 'Today';
    if (next.location) {
        dom.heroWhere.textContent = next.location;
        show(dom.heroWhere, true);
    } else {
        show(dom.heroWhere, false);
    }
}

function buildEventRow(event) {
    const row = document.createElement('button');
    row.type = 'button';
    row.className = event.is_today ? 'event is-today' : 'event';
    row.dataset.eventId = event.id;

    const day = document.createElement('span');
    day.className = 'event-day';
    day.textContent = event.weekday_text;
    const date = document.createElement('small');
    date.textContent = event.day_text;
    day.appendChild(date);

    const body = document.createElement('span');
    body.className = 'event-body';
    const title = document.createElement('span');
    title.className = 'event-title';
    title.textContent = event.title;
    body.appendChild(title);
    if (event.location) {
        const where = document.createElement('span');
        where.className = 'event-where';
        where.textContent = event.location;
        body.appendChild(where);
    }

    const time = document.createElement('span');
    time.className = 'event-time';
    time.textContent = event.time_text;

    row.append(day, body, time);
    return row;
}

function renderSections(payload) {
    const fragment = document.createDocumentFragment();
    let firstTodayRow = null;

    for (const section of payload.sections) {
        const heading = document.createElement('h2');
        heading.className = 'section-heading';
        heading.textContent = section.name;
        fragment.appendChild(heading);

        const list = document.createElement('ul');
        list.className = 'event-list';
        for (const event of section.events) {
            const item = document.createElement('li');
            const row = buildEventRow(event);
            if (event.is_today && firstTodayRow === null) {
                firstTodayRow = row;
            }
            item.appendChild(row);
            list.appendChild(item);
        }
        fragment.appendChild(list);
    }

    dom.sections.replaceChildren(fragment);
    dom.sections.dataset.todayId = firstTodayRow
        ? firstTodayRow.dataset.eventId
        : '';
    show(dom.empty, payload.event_count === 0);
}

function renderWeather(payload) {
    dom.weatherLine.textContent = payload.weather.summary_text;
    dom.weather.disabled = !(payload.weather.days || []).length;
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
    renderHero(payload);
    renderSections(payload);
    renderWeather(payload);
    renderStatus(payload);
}

async function loadBoard() {
    try {
        render(await getJson('/api/board'));
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

function findEvent(eventId) {
    if (!app.payload) {
        return null;
    }
    for (const section of app.payload.sections) {
        for (const event of section.events) {
            if (event.id === eventId) {
                return event;
            }
        }
    }
    return null;
}

function openEvent(eventId) {
    const event = findEvent(eventId);
    if (!event) {
        return;
    }
    dom.eventWhen.textContent =
        `${event.weekday_text} ${event.day_text}${event.time_text ? ' \u00b7 ' + event.time_text : ''}`;
    dom.eventTitle.textContent = event.title;
    if (event.location) {
        dom.eventWhere.textContent = event.location;
        show(dom.eventWhere, true);
    } else {
        show(dom.eventWhere, false);
    }
    if (event.multi_day) {
        dom.eventRange.textContent = `Runs until ${event.end_day}`;
        show(dom.eventRange, true);
    } else {
        show(dom.eventRange, false);
    }
    show(dom.eventOverlay, true);
    dom.eventClose.focus();
}

function openForecast() {
    const days = (app.payload && app.payload.weather.days) || [];
    if (!days.length) {
        return;
    }
    const fragment = document.createDocumentFragment();
    for (const day of days) {
        const item = document.createElement('li');
        const name = document.createElement('span');
        name.className = 'forecast-day';
        name.textContent = dayLabel(day.date);
        const detail = document.createElement('span');
        detail.className = 'forecast-detail';
        detail.textContent = forecastDetail(day);
        item.append(name, detail);
        fragment.appendChild(item);
    }
    dom.forecastList.replaceChildren(fragment);
    show(dom.forecast, true);
    dom.weather.setAttribute('aria-expanded', 'true');
    dom.forecastClose.focus();
}

function dayLabel(isoDate) {
    const parsed = new Date(`${isoDate}T00:00:00`);
    if (Number.isNaN(parsed.getTime())) {
        return isoDate;
    }
    return parsed.toLocaleDateString('en-GB',
        { weekday: 'short', day: 'numeric', month: 'short' });
}

function forecastDetail(day) {
    const bits = [];
    if (day.description) {
        bits.push(day.description);
    }
    const lo = day.temp_min === null || day.temp_min === undefined
        ? '--' : Math.round(day.temp_min);
    const hi = day.temp_max === null || day.temp_max === undefined
        ? '--' : Math.round(day.temp_max);
    bits.push(`${lo}\u00b0 / ${hi}\u00b0`);
    if (day.precip_chance !== null && day.precip_chance !== undefined) {
        bits.push(`${day.precip_chance}% rain`);
    }
    return bits.join('  \u00b7  ');
}

function closeOverlays() {
    show(dom.eventOverlay, false);
    show(dom.forecast, false);
    dom.weather.setAttribute('aria-expanded', 'false');
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
        show(frame, false);
    }
}

function showBoard() {
    closeOverlays();
    setActiveTab('board');
    show(dom.board, true);
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
    if (!url) {
        hideAllFrames();
        dom.frameErrorDetail.textContent = 'No address configured for this tab.';
        show(dom.frameError, true);
        return;
    }
    show(dom.frameError, false);
    for (const [otherName, otherFrame] of Object.entries(dom.frames)) {
        show(otherFrame, otherName === name);
    }
    if (!alreadyLoaded && tab) {
        tab.classList.add('is-loading');
    }
    loadFrame(name);
}

function reportFrameProblem(name, detail) {
    show(dom.frames[name], false);
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

    dom.sections.addEventListener('click', (evt) => {
        const row = evt.target.closest('.event');
        if (row) {
            openEvent(row.dataset.eventId);
        }
    });

    dom.weather.addEventListener('click', openForecast);
    dom.eventClose.addEventListener('click', closeOverlays);
    dom.forecastClose.addEventListener('click', closeOverlays);

    for (const overlay of [dom.eventOverlay, dom.forecast]) {
        overlay.addEventListener('click', (evt) => {
            if (evt.target === overlay) {
                closeOverlays();
            }
        });
    }
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
        show(frame, true);
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
    setActiveTab('board');
    setInterval(loadBoard, BOARD_POLL_MS);
    setInterval(pollState, STATE_POLL_MS);
}

start();
