const express = require("express");
const router = express.Router();

const controller = require("../controllers/outageController");

router.post("/", controller.createOutage);

module.exports = router;