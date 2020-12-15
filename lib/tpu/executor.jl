# config

export TpuStreamExecutorConfig, set_ordinal!

mutable struct TpuStreamExecutorConfig
    handle::Ptr{SE_StreamExecutorConfig}

    function TpuStreamExecutorConfig()
        handle = TpuStreamExecutorConfig_Default()
        config = new(handle)
        finalizer(TpuStreamExecutorConfig_Free, config)
    end
end

Base.unsafe_convert(::Type{Ptr{SE_StreamExecutorConfig}}, x::TpuStreamExecutorConfig) = x.handle

set_ordinal!(sec::TpuStreamExecutorConfig, o::Integer) =
    TpuStreamExecutorConfig_SetOrdinal(sec, o)


# device options

mutable struct SEDeviceOptions
    handle::Ptr{SE_DeviceOptions}
    function SEDeviceOptions(flags::Cuint)
        TpuExecutor_NewDeviceOptions(flags)
    end
end


# executor

export TpuExecutor, platform_device_count

mutable struct TpuExecutor
    handle::Ptr{SE_StreamExecutor}
    function TpuExecutor(platform::TpuPlatform; config = TpuStreamExecutorConfig())
        handle = with_status() do status
            TpuPlatform_GetExecutor(platform, config, status)
        end
        executor = new(handle)
        finalizer(TpuExecutor_Free, executor)
    end
end

Base.unsafe_convert(::Type{Ptr{SE_StreamExecutor}}, x::TpuExecutor) = x.handle

function initialize!(e::TpuExecutor, ordinal = 0, options = SEDeviceOptions(UInt32(0)))
    with_status() do s
        TpuExecutor_Init(e, ordinal, options, s)
    end
end

platform_device_count(e::TpuExecutor) = TpuExecutor_PlatformDeviceCount(e)


# allocations

export SE_DeviceMemoryBase, allocate!, deallocate!, memory_usage

SE_DeviceMemoryBase() = SE_DeviceMemoryBase(C_NULL, 0, 0)

function allocate!(e::TpuExecutor, size::UInt64, memory_space::Int64)
    TpuExecutor_Allocate(e, size, memory_space)
end

function deallocate!(e::TpuExecutor, mem::SE_DeviceMemoryBase)
    rmem = Ref{SE_DeviceMemoryBase}(mem)
    TpuExecutor_Deallocate(e, rmem)
end

function memory_usage(e::TpuExecutor)
    free = Ref{Int64}()
    total = Ref{Int64}()
    TpuExecutor_DeviceMemoryUsage(e, free, total)
    (free=free[], total=total[])
end
