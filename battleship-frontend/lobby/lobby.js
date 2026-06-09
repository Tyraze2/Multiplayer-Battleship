const socket = new WebSocket("ws://localhost:8080/ws");

// 1. Fixed array syntax
const games = ["test", "test2"]; 

socket.addEventListener('open', (event) => {
    console.log("by pure hopes and dreams we somehow connected mashallah");
});

// 2. Fixed loop syntax (.length instead of len())
for (let i = 0; i < games.length; i++) {
    const gameSelect = document.createElement('div');
    gameSelect.textContent = games[i];
    
    gameSelect.addEventListener('click', () => {
        console.log(`joined game ${games[i]}`);
    });
    
    document.querySelector('#games').appendChild(gameSelect);
}