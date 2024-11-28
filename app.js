const express = require('express')
const app = express()
const path = require('path')
const port = 3000

app.use(express.static(path.join(__dirname, 'public')))

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, './index.html'))
})

app.listen(port, () => {
    console.log(`Unikernel app listening on port ${port}`)
})
