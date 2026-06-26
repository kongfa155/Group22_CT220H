const express = require("express");
const router = express.Router();

const controller = require("../controllers/outageController");

router.post("/raw", controller.createRawOutage);
module.exports = router;