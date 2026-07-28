const express = require("express");
const cors = require("cors");

const outageRoutes = require("./routes/outages");

const app = express();

app.use(cors());
app.use(express.json());

app.use("/api/outages", outageRoutes);
app.use("/api/boundaries", require("./routes/boundaries"));
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log("Your service is live");
});