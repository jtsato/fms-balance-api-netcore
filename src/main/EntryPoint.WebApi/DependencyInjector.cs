using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using Core.Commons;
using EntryPoint.WebApi.Commons;
using EntryPoint.WebApi.Commons.Exceptions;
using EntryPoint.WebApi.Commons.Filters;
using Microsoft.Extensions.DependencyInjection;

namespace EntryPoint.WebApi;

[ExcludeFromCodeCoverage]
public static class DependencyInjector
{
    public static Dictionary<Type, ServiceLifetime> ConfigureServices(IServiceCollection services)
    {
        AddSharedServices(services);
        AddEntryPointServices(services);

        return BuildLifetimeByType(services);
    }

    private static void AddSharedServices(IServiceCollection services)
    {
        services.AddSingleton<IServiceResolver, ServiceResolver>();
        services.AddSingleton<IGetDateTime, GetDateTime>();
        services.AddTransient<ILoggerAdapter, LoggerAdapter<ExceptionHandlerFilterAttribute>>();
    }

    private static void AddEntryPointServices(IServiceCollection services)
    {
        services.AddLocalization(options => options.ResourcesPath = "Resources");
        services.AddSingleton<IExceptionHandler, ExceptionHandler>();
        services.AddSingleton<IGetCorrelationId, GetCorrelationId>();
    }

    private static Dictionary<Type, ServiceLifetime> BuildLifetimeByType(IServiceCollection services)
    {
        Dictionary<Type, ServiceLifetime> lifetimeByType = new Dictionary<Type, ServiceLifetime>();
        foreach (ServiceDescriptor service in services)
        {
            if (service.Lifetime != ServiceLifetime.Singleton) continue;
            if (lifetimeByType.ContainsKey(service.ServiceType)) continue;
            lifetimeByType.Add(service.ServiceType, service.Lifetime);
        }

        return lifetimeByType;
    }
}