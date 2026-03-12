const express = require('express');
const app = express();
app.use(express.json());

// GET API
app.get('/api/food', (req, res) => {
  res.json({ message: 'Welcome to FoodExpress API!', items: ['Pizza', 'Burger', 'Sushi'] });
});

app.listen(5000, () =>
    console.log('EXPRESS Server Started at Port No: 5000');
});

// POST API - Add new food item
app.post('/api/food', (req, res) => {
  const { name } = req.body;
  res.json({ message: `Food item '${name}' added successfully!` });
});

// DELETE API - Remove a food item
app.delete('/api/food/:id', (req, res) => {
  res.json({ message: `Food item ${req.params.id} deleted successfully!` });
});
