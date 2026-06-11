const socket = new WebSocket("ws://localhost:8080/ws");

socket.addEventListener('message', event => {
    const packet = JSON.parse(event.packet);
    console.log(packet);

    if (packet == "active_lobbies") {
        lobbyUI(packet); // every time recieving new lobbies, UI should be updated (unless it hates me)
    }
});

const games = [
    {name: "test", players: 1 },
    {name: "test2", players: 2 }
]; // barebones and not the way packets are gonna be recieved but good enough to test for now


socket.addEventListener('open', (event) => {
    console.log("by pure hopes and dreams we somehow connected mashallah");
});

function lobbyUI(games) {
    // todo: sort games by player count (so that full games are at the bottom)
    
    const gamesContainer = document.querySelector('#lobby-list')
    gamesContainer.innerHTML = '';

    for (let i = 0; i < games.length; i++) {
        const game = document.createElement('li');
        game.classList.add('game');
        if ( games[i].players == 2 ) {
            game.innerHTML = `<span>${games[i].name}</span><span class="full-status">Full</span>`;
        } // full game nono!
        else {
            game.innerHTML = `<span>${games[i].name}</span><button class="join-btn">Join</button>`
        } // not full game yesyes!
        
        gamesContainer.appendChild(game); // they had baby child
    }
}

// ok im gonna leave for school now remind me to WORK

lobbyUI(games);