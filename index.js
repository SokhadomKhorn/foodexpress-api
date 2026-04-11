const e1 = require('express');
const app = e1();

app.get('/search', (req, res) => {
    res.send('<html><body>INSIDE SEARCH API..</body></html>');
});

app.get('/view', (req, res) => {
    res.send('<html><body>INSIDE VIEW API..</body></html>');
});

app.listen(5000, "0.0.0.0", function() {
    console.log('EXPRESS Server Started at Port No: 5000');
});
