import ast
import operator
from typing import Annotated

from haystack.tools import tool

OPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Pow: operator.pow,
    ast.Mod: operator.mod,
    ast.USub: operator.neg,
}


def _eval(node):
    if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
        return node.value
    if isinstance(node, ast.BinOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_eval(node.left), _eval(node.right))
    if isinstance(node, ast.UnaryOp) and type(node.op) in OPS:
        return OPS[type(node.op)](_eval(node.operand))
    raise ValueError("only numbers and + - * / ** % are allowed")


@tool
def calculate(expression: Annotated[str, "An arithmetic expression, e.g. (2026 - 1969) * 12"]) -> str:
    """Evaluate an arithmetic expression exactly. Use it instead of doing math in your head."""
    return str(_eval(ast.parse(expression, mode="eval").body))
