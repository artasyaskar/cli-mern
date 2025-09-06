import { Router } from 'express';
import { getAllProducts, createProduct } from '../controllers/productController';

const router = Router();

router.route('/')
  .get(getAllProducts)
  .post(createProduct);

export default router;
