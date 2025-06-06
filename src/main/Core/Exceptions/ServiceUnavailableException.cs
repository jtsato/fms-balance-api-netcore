﻿using System.Diagnostics.CodeAnalysis;

namespace Core.Exceptions;

[ExcludeFromCodeCoverage]
public sealed class ServiceUnavailableException(string message, params object[] args) : CoreException(message, args)
{
    public override string ToString()
    {
        return $"{base.ToString()}, Parameters: {string.Join(", ", Parameters ?? [])}";
    }

}
