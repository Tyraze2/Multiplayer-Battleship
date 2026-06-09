const socket = new WebSocket("ws://localhost:8080/ws");
const games = new Array();
games.append("test");
games.append("test2");

socket.addEventListener('open', event, () => {
    console.log("by pure hopes and dreams we somehow connected mashallah");
});

for (let i = 0; i < len(games); i++) {
    const gameSelect = document.createElement('div');
    gameSelect.textContent = games[i];
    gameSelect.addEventListener('click', () => {
        console.log(`joined game ${games[i]}`);
    });
    document.querySelector('#games').appendChild(gameSelect);
}