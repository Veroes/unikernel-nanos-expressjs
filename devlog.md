# Developer Log

## 2024-11-28

**Objective**: Create a simple Express JS app with fancy looking html file (SPA). If possible build it into a unikernel \
**Task**:

-   Do `npm init`
-   Do `npm install express`
-   Create `index.html`. add some cool design to it
-   Test the app see if it works to do `GET` in browser or even in Postman
-   (Optional) CRUD Capabilities

**Next Steps**: Implement Nanos to exisiting app

**Note**: Theres a config to specifices the number of `CPUs` core the unikernel is allowed to use, This need to be considered in next update

```
{
    "RunConfig": {
        "GPUs": 1,
        "GPUType": "nvidia-tesla-t4"
    }
}
```

There's also memory allocations set to `QEMU` by default is 128MIB. use "M" or "G" to signify value in megabytes or gigabytes respectively.

```
{
    "RunConfig": {
        "Memory": "2G"
    }
}
```

In the `RunConfig` attributes, I use `"Debug": true` and `"ShowDebug": true`, when it fully ready in production, make sure to delete this
