const socket = new WebSocket("ws://localhost:8080/ws");

socket.addEventListener('message', event => {
    const packet = JSON.parse(event.packet);
    console.log(packet);

    if (packet == "active_lobbies") {
        lobbyUI(packet);
    }
});

const games = ["test", "test2"]; 

socket.addEventListener('open', (event) => {
    console.log("by pure hopes and dreams we somehow connected mashallah");
});

function lobbyUI(games) {
    const gamesContainer = document.querySelector('#lobby-list')
    
    for (let i = 0; i < games.length; i++) {
        const game = document.createElement('li');
        game.textContent = games[i];
        gamesContainer.appendChild(game);
    }
}

lobbyUI(games);