const express = require("express");
const cors = require("cors");

const outageRoutes = require("./routes/outages");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/outages", outageRoutes);

app.listen(3000, () => {
    console.log("Server running at http://localhost:3000");
});