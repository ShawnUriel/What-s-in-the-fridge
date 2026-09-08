import { Router } from 'express';
import { matchRecipes, listIngredients } from '../controllers/recipeController.js';

const router = Router();

router.post('/recipes/match', matchRecipes);
router.get('/ingredients', listIngredients);

export default router;
