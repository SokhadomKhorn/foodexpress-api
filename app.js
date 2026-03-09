const express = require('express');
const app = express();
app.use(express.json());

// GET API
app.get('/api/food', (req, res) => {
  res.json({ message: 'Welcome to FoodExpress API!', items: ['Pizza', 'Burger', 'Sushi'] });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});