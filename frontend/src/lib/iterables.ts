export function zip<T, U>(array1: Array<T>, array2: Array<U>): Array<[T, U]> {
    const length = Math.min(array1.length, array2.length);
    const result: Array<[T, U]> = []
    for (let i = 0; i < length; i++) {
        result.push([array1[i], array2[i]])
    }
    return result
}