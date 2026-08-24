namespace PosCloud.Domain.Common;

public class Result<T>
{
    public bool IsSuccess { get; init; }
    public T? Value { get; init; }
    public string? Error { get; init; }
    public string? Code { get; init; }

    public static Result<T> Success(T value) => new() { IsSuccess = true, Value = value };
    public static Result<T> Fail(string code, string error) => new() { IsSuccess = false, Code = code, Error = error };
}

public class Result
{
    public bool IsSuccess { get; init; }
    public string? Error { get; init; }
    public string? Code { get; init; }
    public static Result Success() => new() { IsSuccess = true };
    public static Result Fail(string code, string error) => new() { IsSuccess = false, Code = code, Error = error };
}
