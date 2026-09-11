import axios from 'axios';

export default axios.create({
    baseURL: 'http://localhost:8080', // Replace with your EC2 IP when deployed (e.g. 'http://18.221.67.127:8080')
    headers: {
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true'
    }
});