const express = require("express");
const router = express.Router();

const mapController = require("../controllers/outageMapController");
const controller = require("../controllers/outageController");

router.post("/raw", controller.createRawOutage);
router.get("/by-ward", mapController.getOutagesByWard);
module.exports = router;