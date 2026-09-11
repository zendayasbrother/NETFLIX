import axios from 'axios';

export default axios.create({
    baseURL:'http://18.221.67.127:8080',
    headers: {
        'Content-Type': 'application/json',
    },
});
