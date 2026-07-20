const express = require("express");
const router = express.Router();
const controller = require("../controllers/boundaryController");

router.get("/", controller.getAllBoundaries);
module.exports = router;