class ProductHelper {
  static String getEmojiForName(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return '🥑';

    // Vegetables & Roots
    if (lower.contains('карто') || lower.contains('пюре') || lower.contains('драник') || lower.contains('фри')) return '🥔';
    if (lower.contains('помидор') || lower.contains('томат') || lower.contains('черри')) return '🍅';
    if (lower.contains('огурец') || lower.contains('огурц') || lower.contains('корнишон')) return '🥒';
    if (lower.contains('морков')) return '🥕';
    if (lower.contains('чеснок')) return '🧄';
    if (lower.contains('лук') || lower.contains('шалот') || lower.contains('порей')) return '🧅';
    if (lower.contains('кукуруз')) return '🌽';
    if (lower.contains('горох') || lower.contains('горошек') || lower.contains('нут') || lower.contains('боб') || lower.contains('фасол')) return '🫛';
    if (lower.contains('перец') || lower.contains('паприк')) return lower.contains('остр') || lower.contains('чили') ? '🌶' : '🫑';
    if (lower.contains('броккол')) return '🥦';
    if (lower.contains('капуст') || lower.contains('салат') || lower.contains('шпинат') || lower.contains('зелен') || lower.contains('укроп') || lower.contains('петрушк') || lower.contains('руккол')) return '🥬';
    if (lower.contains('гриб') || lower.contains('шампиньон') || lower.contains('вешенк') || lower.contains('лисичк')) return '🍄';
    if (lower.contains('авокадо')) return '🥑';
    if (lower.contains('баклажан')) return '🍆';
    if (lower.contains('тыкв')) return '🎃';

    // Dairy & Eggs
    if (lower.contains('сыр') || lower.contains('пармезан') || lower.contains('моцарелл') || lower.contains('чеддер') || lower.contains('сулугуни') || lower.contains('гауда') || lower.contains('бри') || lower.contains('дорблю')) return '🧀';
    if (lower.contains('яйц') || lower.contains('яйцо') || lower.contains('омлет')) return '🥚';
    if (lower.contains('масло') && (lower.contains('слив') || lower.contains('крем'))) return '🧈';
    if (lower.contains('оливк') || lower.contains('маслин') || lower.contains('раст')) return '🫒';
    if (lower.contains('молок') || lower.contains('сливк') || lower.contains('кефир') || lower.contains('ряженк') || lower.contains('йогурт') || lower.contains('творог') || lower.contains('сметан') || lower.contains('сырок')) return '🥛';

    // Meat & Poultry
    if (lower.contains('куриц') || lower.contains('цыпл') || lower.contains('голен') || lower.contains('бедр') || lower.contains('крыл') || lower.contains('наггетс')) return '🍗';
    if (lower.contains('мясо') || lower.contains('говядин') || lower.contains('свинин') || lower.contains('стейк') || lower.contains('индейк') || lower.contains('фарш') || lower.contains('вырезк')) return '🥩';
    if (lower.contains('бекон') || lower.contains('грудинк')) return '🥓';
    if (lower.contains('колбас') || lower.contains('сосиск') || lower.contains('сардельк') || lower.contains('ветчин') || lower.contains('салями')) return '🌭';

    // Fish & Seafood
    if (lower.contains('рыб') || lower.contains('лосос') || lower.contains('семг') || lower.contains('форел') || lower.contains('тунец') || lower.contains('треск') || lower.contains('сибас') || lower.contains('минтай') || lower.contains('судак') || lower.contains('сельдь') || lower.contains('шпрот')) return '🐟';
    if (lower.contains('креветк') || lower.contains('лангустин')) return '🦐';
    if (lower.contains('краб')) return '🦀';
    if (lower.contains('кальмар') || lower.contains('осьминог')) return '🦑';

    // Bakery & Grains
    if (lower.contains('хлеб') || lower.contains('батон') || lower.contains('багет') || lower.contains('булк') || lower.contains('чиабатт') || lower.contains('лаваш') || lower.contains('тост')) return '🍞';
    if (lower.contains('круассан')) return '🥐';
    if (lower.contains('макарон') || lower.contains('паст') || lower.contains('спагетти') || lower.contains('лапш') || lower.contains('пенне') || lower.contains('рамен')) return '🍝';
    if (lower.contains('рис') || lower.contains('ризотто') || lower.contains('плов')) return '🍚';
    if (lower.contains('пельмен') || lower.contains('вареник') || lower.contains('хинкал') || lower.contains('дамплинг')) return '🥟';
    if (lower.contains('гречк') || lower.contains('овсянк') || lower.contains('каш') || lower.contains('хлопь') || lower.contains('мюсли') || lower.contains('гранол')) return '🥣';

    // Fruits & Berries
    if (lower.contains('яблок')) return '🍎';
    if (lower.contains('груш')) return '🍐';
    if (lower.contains('банан')) return '🍌';
    if (lower.contains('лимон') || lower.contains('лайм')) return '🍋';
    if (lower.contains('апельсин') || lower.contains('мандарин') || lower.contains('грейпфрут') || lower.contains('цитрус')) return '🍊';
    if (lower.contains('арбуз')) return '🍉';
    if (lower.contains('дын')) return '🍈';
    if (lower.contains('виноград')) return '🍇';
    if (lower.contains('клубник') || lower.contains('земляник')) return '🍓';
    if (lower.contains('черник') || lower.contains('голубик')) return '🫐';
    if (lower.contains('малин') || lower.contains('ежевик') || lower.contains('вишн') || lower.contains('черешн')) return '🍒';
    if (lower.contains('персик') || lower.contains('нектарин') || lower.contains('абрикос')) return '🍑';
    if (lower.contains('манго')) return '🥭';
    if (lower.contains('ананас')) return '🍍';
    if (lower.contains('киви')) return '🥝';
    if (lower.contains('кокос')) return '🥥';

    // Prepared / Fast Food / Meals
    if (lower.contains('пицц')) return '🍕';
    if (lower.contains('бургер') || lower.contains('гамбургер') || lower.contains('чизбургер')) return '🍔';
    if (lower.contains('сэндвич') || lower.contains('бутерброд')) return '🥪';
    if (lower.contains('суп') || lower.contains('борщ') || lower.contains('солянк') || lower.contains('бульон') || lower.contains('том ям') || lower.contains('щи')) return '🍲';
    if (lower.contains('соус') || lower.contains('песто') || lower.contains('кетчуп') || lower.contains('майонез') || lower.contains('горчиц') || lower.contains('консерв') || lower.contains('банк')) return '🥫';

    // Sweets & Drinks
    if (lower.contains('торт') || lower.contains('пирожн') || lower.contains('бисквит')) return '🍰';
    if (lower.contains('печень') || lower.contains('вафл')) return '🍪';
    if (lower.contains('шоколад') || lower.contains('конфет')) return '🍫';
    if (lower.contains('морожен')) return '🍦';
    if (lower.contains('сок') || lower.contains('морс') || lower.contains('компот') || lower.contains('лимонад') || lower.contains('смузи')) return '🧃';
    if (lower.contains('чай')) return '🍵';
    if (lower.contains('кофе') || lower.contains('капучино') || lower.contains('латте') || lower.contains('эспрессо')) return '☕';
    if (lower.contains('мед')) return '🍯';
    if (lower.contains('орех') || lower.contains('миндал') || lower.contains('фундук') || lower.contains('кешью') || lower.contains('арахис')) return '🥜';

    return '🥑';
  }

  static String getCategoryForName(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return 'Овощи и зелень';

    if (lower.contains('карто') || lower.contains('помидор') || lower.contains('томат') ||
        lower.contains('огурец') || lower.contains('морков') || lower.contains('чеснок') ||
        lower.contains('лук') || lower.contains('кукуруз') || lower.contains('горох') ||
        lower.contains('перец') || lower.contains('броккол') || lower.contains('капуст') ||
        lower.contains('салат') || lower.contains('шпинат') || lower.contains('зелен') ||
        lower.contains('гриб') || lower.contains('авокадо') || lower.contains('баклажан') ||
        lower.contains('тыкв')) {
      return 'Овощи и зелень';
    }

    if (lower.contains('яблок') || lower.contains('груш') || lower.contains('банан') ||
        lower.contains('лимон') || lower.contains('лайм') || lower.contains('апельсин') ||
        lower.contains('мандарин') || lower.contains('арбуз') || lower.contains('дын') ||
        lower.contains('виноград') || lower.contains('клубник') || lower.contains('черник') ||
        lower.contains('малин') || lower.contains('персик') || lower.contains('манго') ||
        lower.contains('ананас') || lower.contains('киви')) {
      return 'Фрукты и ягоды';
    }

    if (lower.contains('сыр') || lower.contains('молок') || lower.contains('сливк') ||
        lower.contains('кефир') || lower.contains('йогурт') || lower.contains('творог') ||
        lower.contains('сметан') || lower.contains('масло')) {
      return 'Молочные продукты';
    }

    if (lower.contains('куриц') || lower.contains('мясо') || lower.contains('говядин') ||
        lower.contains('свинин') || lower.contains('стейк') || lower.contains('индейк') ||
        lower.contains('фарш') || lower.contains('бекон') || lower.contains('колбас') ||
        lower.contains('сосиск') || lower.contains('ветчин')) {
      return 'Мясо и птица';
    }

    if (lower.contains('рыб') || lower.contains('лосос') || lower.contains('семг') ||
        lower.contains('форел') || lower.contains('тунец') || lower.contains('креветк') ||
        lower.contains('краб') || lower.contains('кальмар')) {
      return 'Рыба и морепродукты';
    }

    if (lower.contains('хлеб') || lower.contains('батон') || lower.contains('багет') ||
        lower.contains('макарон') || lower.contains('паст') || lower.contains('спагетти') ||
        lower.contains('рис') || lower.contains('круп') || lower.contains('гречк') ||
        lower.contains('овсянк') || lower.contains('мук') || lower.contains('сахар') ||
        lower.contains('соль') || lower.contains('консерв') || lower.contains('масло')) {
      return 'Бакалея';
    }

    if (lower.contains('сок') || lower.contains('морс') || lower.contains('компот') ||
        lower.contains('лимонад') || lower.contains('чай') || lower.contains('кофе') ||
        lower.contains('вод')) {
      return 'Напитки';
    }

    if (lower.contains('суп') || lower.contains('борщ') || lower.contains('пицц') ||
        lower.contains('бургер') || lower.contains('сэндвич') || lower.contains('плов') ||
        lower.contains('пельмен') || lower.contains('вареник')) {
      return 'Готовая еда';
    }

    return 'Овощи и зелень';
  }
}
