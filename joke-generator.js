#!/usr/bin/env node

/**
 * Enhanced Joke Generator CLI Tool
 * 
 * Features:
 * - Colorful terminal output using chalk
 * - Category selection (programming, general, knockknock, random)
 * - Fetch multiple jokes at once
 * - Save joke history to joke-history.txt
 * - Retry logic for network failures
 * - Command-line interface with yargs
 * 
 * Usage:
 *   node joke-generator.js                              # Get one random joke
 *   node joke-generator.js --category programming       # Get programming joke
 *   node joke-generator.js --count 5                    # Get 5 random jokes
 *   node joke-generator.js --category general --count 3 # Get 3 general jokes
 *   node joke-generator.js --no-color                   # Disable colors
 *   node joke-generator.js --history                    # View joke history
 * 
 * Requirements:
 *   - Node.js 14+ (fetch built-in for Node 18+)
 *   - Dependencies: chalk, yargs, node-fetch (for Node < 18)
 */

const chalk = require('chalk');
const yargs = require('yargs/yargs');
const { hideBin } = require('yargs/helpers');
const fs = require('fs').promises;
const path = require('path');

// For Node < 18 compatibility
if (typeof fetch === 'undefined') {
    global.fetch = require('node-fetch');
}

const HISTORY_FILE = path.join(__dirname, 'joke-history.txt');
const MAX_RETRIES = 3;
const RETRY_DELAY = 1000; // 1 second

// Available joke categories
const CATEGORIES = {
    programming: 'programming',
    general: 'general', 
    knockknock: 'knockknock',
    random: 'random'
};

/**
 * Fetch a joke from the API with retry logic
 */
async function fetchJokeWithRetry(category = 'random', retryCount = 0) {
    try {
        let url = 'https://official-joke-api.appspot.com/';
        
        if (category === 'random') {
            url += 'random_joke';
        } else {
            url += `jokes/${category}/random`;
        }

        const res = await fetch(url);
        if (!res.ok) {
            throw new Error(`HTTP ${res.status}: ${res.statusText}`);
        }
        
        const data = await res.json();
        // Handle different response formats
        const joke = Array.isArray(data) ? data[0] : data;
        
        return {
            setup: joke.setup,
            punchline: joke.punchline,
            category: joke.type || category,
            id: joke.id || Date.now()
        };
    } catch (error) {
        if (retryCount < MAX_RETRIES) {
            console.log(chalk.yellow(`⚠ Retry ${retryCount + 1}/${MAX_RETRIES}: ${error.message}`));
            await new Promise(resolve => setTimeout(resolve, RETRY_DELAY));
            return fetchJokeWithRetry(category, retryCount + 1);
        }
        throw new Error(`Failed to fetch joke after ${MAX_RETRIES} retries: ${error.message}`);
    }
}

/**
 * Display a joke with color formatting
 */
function displayJoke(joke, index = null, useColor = true) {
    const prefix = index !== null ? `${chalk.cyan.bold(`Joke ${index}:`)} ` : '';
    const category = useColor ? chalk.magenta(`[${joke.category}]`) : `[${joke.category}]`;
    const setup = useColor ? chalk.blue(joke.setup) : joke.setup;
    const punchline = useColor ? chalk.green.bold(joke.punchline) : joke.punchline;
    
    console.log(`${prefix}${category}`);
    console.log(setup);
    console.log(punchline);
    console.log(); // Empty line for spacing
}

/**
 * Save joke to history file
 */
async function saveJokeToHistory(joke) {
    try {
        const timestamp = new Date().toISOString();
        const historyEntry = `[${timestamp}] [${joke.category}] ${joke.setup} | ${joke.punchline}\n`;
        await fs.appendFile(HISTORY_FILE, historyEntry, 'utf8');
    } catch (error) {
        console.error(chalk.red(`Error saving to history: ${error.message}`));
    }
}

/**
 * Display joke history
 */
async function showHistory() {
    try {
        const history = await fs.readFile(HISTORY_FILE, 'utf8');
        const lines = history.split('\n').filter(line => line.trim());
        
        if (lines.length === 0) {
            console.log(chalk.yellow('No jokes in history yet!'));
            return;
        }
        
        console.log(chalk.blue.bold(`📚 Joke History (${lines.length} jokes):`));
        console.log(chalk.gray('═'.repeat(50)));
        
        lines.slice(-10).forEach((line, index) => {
            const match = line.match(/\[(.*?)\] \[(.*?)\] (.*?) \| (.*)/);
            if (match) {
                const [, timestamp, category, setup, punchline] = match;
                const date = new Date(timestamp).toLocaleDateString();
                console.log(`${chalk.cyan(index + 1)}. ${chalk.magenta(`[${category}]`)} ${chalk.gray(date)}`);
                console.log(`   ${chalk.blue(setup)}`);
                console.log(`   ${chalk.green(punchline)}`);
                console.log();
            }
        });
        
        if (lines.length > 10) {
            console.log(chalk.gray(`... and ${lines.length - 10} more jokes`));
        }
    } catch (error) {
        if (error.code === 'ENOENT') {
            console.log(chalk.yellow('No joke history found. Start fetching jokes to build your history!'));
        } else {
            console.error(chalk.red(`Error reading history: ${error.message}`));
        }
    }
}

/**
 * Main function to fetch and display jokes
 */
async function main() {
    const argv = yargs(hideBin(process.argv))
        .usage('Usage: $0 [options]')
        .option('category', {
            alias: 'c',
            describe: 'Joke category',
            choices: Object.keys(CATEGORIES),
            default: 'random'
        })
        .option('count', {
            alias: 'n',
            describe: 'Number of jokes to fetch',
            type: 'number',
            default: 1,
            coerce: (count) => Math.min(Math.max(1, count), 10) // Limit 1-10
        })
        .option('color', {
            describe: 'Enable colorful output',
            type: 'boolean',
            default: true
        })
        .option('history', {
            describe: 'Show joke history',
            type: 'boolean'
        })
        .example('$0', 'Get one random joke')
        .example('$0 --category programming', 'Get a programming joke')
        .example('$0 --count 3', 'Get 3 random jokes')
        .example('$0 --category general --count 2 --no-color', 'Get 2 general jokes without colors')
        .help()
        .alias('help', 'H')
        .version('1.0.0')
        .argv;

    // Handle history display
    if (argv.history) {
        await showHistory();
        return;
    }

    // Set chalk level based on color option
    if (!argv.color) {
        chalk.level = 0;
    }

    try {
        console.log(chalk.blue.bold('🎭 Joke Generator'));
        console.log(chalk.gray('═'.repeat(30)));
        
        const jokes = [];
        
        // Fetch jokes
        for (let i = 0; i < argv.count; i++) {
            const joke = await fetchJokeWithRetry(argv.category);
            jokes.push(joke);
            await saveJokeToHistory(joke);
        }
        
        // Display jokes
        jokes.forEach((joke, index) => {
            const jokeNumber = argv.count > 1 ? index + 1 : null;
            displayJoke(joke, jokeNumber, argv.color);
        });
        
        console.log(chalk.gray(`✨ Fetched ${jokes.length} joke(s) | History saved to ${path.basename(HISTORY_FILE)}`));
        
    } catch (error) {
        console.error(chalk.red.bold('❌ Error:'), chalk.red(error.message));
        console.log(chalk.yellow('💡 Try again later or check your internet connection.'));
        process.exit(1);
    }
}

// Run the program
if (require.main === module) {
    main().catch(console.error);
}

module.exports = { fetchJokeWithRetry, displayJoke, saveJokeToHistory, showHistory };