const socket = new WebSocket("ws://localhost:8080/ws");

socket.addEventListener('message', event => {
    const packet = JSON.parse(event.data);
    console.log(packet);

    if (packet.status == "active_lobbies") {
        lobbyUI(packet); // every time recieving new lobbies, UI should be updated (unless it hates me)
    }
});

// create a game

function startGame() {
    gameName = gamename.value;
    socket.send(JSON.stringify({action: "start_game", name: gameName}));
    if (gameName == "") {
        alert("pls enter game name ok be nice. also do you like this game? i like it a lot. #wholesomechungus");
        return;
    } else if (socket.readyState === WebSocket.OPEN) {
        window.location.href = `../game/game.html?game=${encodeURIComponent(gamename)}&role=creator`
    } else {
        alert("something went wrong... likely server side :( please tell either valentin or isabel about this problem to fix")
    }
}

const games = [
    {name: "test", players: 2 },
    {name: "test2", players: 1 },
    {name: "test3", players: 0 },
    {name: "test4", players: 3 },
    // add 5 more tests
    {name: "test5", players: 2 },
]; // barebones and not the way packets are gonna be recieved but good enough to test for now

socket.addEventListener('open', (event) => {
    console.log("by pure hopes and dreams we somehow connected mashallah");
});

function lobbyUI(games) {    
    const sortedGames = games.sort((a, b) => a.players - b.players);

    const gamesContainer = document.querySelector('#lobby-list')
    gamesContainer.innerHTML = '';

    for (let i = 0; i < games.length; i++) {
        const game = document.createElement('li');
        game.classList.add('game');
        if ( games[i].players == 2 ) {
            game.innerHTML = `<span>${sortedGames[i].name}'s room</span><span class="full-status">Full</span>`;
        } // full game nono!
        else if (games[i].players > 2) {
            game.innerHTML = `<span>${sortedGames[i].name}'s room</span><span class="ivalid">Invalid Game</span>`;
        } // no handling for sorting these to be at the btotom but lowk this will never happen i think so it's fine
        else if (games[i].players < 1) {
            game.innerHTML = `<span>${sortedGames[i].name}'s room</span><span class="ivalid">Invalid Game</span>`;
        }
        else {
            game.innerHTML = `<span>${sortedGames[i].name}'s room</span><button class="join-btn">Join</button>`
        } // not full game yesyes!
        
        gamesContainer.appendChild(game); // they had baby child
        
        const joinBtn = game.querySelector('.join-btn');
        if (joinBtn) {
            joinBtn.addEventListener('click', (event) => {
                window.location.href = `../game/game.html?game=${encodeURIComponent(sortedGames[i].name)}&role=joiner`;
            });
        }
    }
}

lobbyUI(games);