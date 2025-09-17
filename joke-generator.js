// joke-generator.js
// Run: node joke-generator.js

// For Node 18+, fetch is built-in. For older Node versions, install node-fetch and uncomment the next line:
// const fetch = require('node-fetch');

async function getRandomJoke() {
    const res = await fetch('https://official-joke-api.appspot.com/random_joke');
    if (!res.ok) throw new Error('Failed to fetch joke');
    const joke = await res.json();
    return `${joke.setup}\n${joke.punchline}`;
}

getRandomJoke()
    .then(console.log)
    .catch(console.error);